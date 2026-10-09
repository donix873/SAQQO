"""Opt-in moderator access: independent password + TOTP, short opaque sessions."""
import base64, hashlib, hmac, os, secrets, struct, time
from fastapi import HTTPException, Header
from pydantic import BaseModel, Field

sessions: dict[str, float] = {}
class Login(BaseModel):
    password: str = Field(min_length=1, max_length=200)
    otp: str = Field(pattern=r'^\d{6}$')

def otp_at(secret: str, counter: int):
    key = base64.b32decode(secret.upper() + '='*((-len(secret))%8))
    raw = hmac.new(key, struct.pack('>Q',counter), hashlib.sha1).digest()
    offset = raw[-1] & 15
    value = (struct.unpack('>I',raw[offset:offset+4])[0] & 0x7fffffff) % 1000000
    return f'{value:06d}'

def login(request: Login):
    password = os.getenv('SAQGO_ADMIN_PASSWORD','')
    secret = os.getenv('SAQGO_ADMIN_TOTP_SECRET','')
    if len(password) < 20 or not secret:
        raise HTTPException(503, 'Moderator access is not configured')
    try:
        valid_otp = any(hmac.compare_digest(request.otp,otp_at(secret,int(time.time()/30)+delta)) for delta in (-1,0,1))
    except (ValueError, base64.binascii.Error):
        raise HTTPException(503, 'Moderator access is not configured')
    if not hmac.compare_digest(password,request.password) or not valid_otp:
        raise HTTPException(401, 'Invalid authentication')
    for token, expiry in list(sessions.items()):
        if expiry <= time.time():sessions.pop(token,None)
    if len(sessions) >= 100:raise HTTPException(429,'Too many sessions')
    token = secrets.token_urlsafe(32);sessions[token]=time.time()+900
    return {'access_token':token,'expires_in':900,'role':'moderator'}

def moderator(authorization: str | None = Header(default=None)):
    token = (authorization or '').removeprefix('Bearer ')
    if sessions.get(token,0) <= time.time():
        raise HTTPException(401,'Authentication required')
    return hashlib.sha256(token.encode()).hexdigest()[:16]
