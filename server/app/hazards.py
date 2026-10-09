"""Moderated coarse observations, never individual routes or persistent user IDs."""
from __future__ import annotations
import json, os, sqlite3, time, uuid
from pathlib import Path
from typing import Literal
from pydantic import BaseModel, Field, model_validator, ConfigDict
from .models import Point

CATEGORIES = Literal['road_bump', 'ice', 'closure', 'sidewalk']

class Observation(BaseModel):
    model_config = ConfigDict(extra="forbid")
    point: Point
    category: CATEGORIES
    confidence: float = Field(ge=0, le=1)
    accuracy_meters: float = Field(gt=0, le=65)
    observed_at: str
    consent_version: Literal['1.3']
    @model_validator(mode='after')
    def validate_city(self):
        from datetime import datetime, timezone
        date = datetime.fromisoformat(self.observed_at.replace('Z', '+00:00'))
        if date.tzinfo is None or abs((datetime.now(timezone.utc)-date).total_seconds()) > 86400:
            raise ValueError('Observation must be recent and timezone-aware')
        if not (50.05 <= self.point.latitude <= 50.48 and 66.45 <= self.point.longitude <= 67.38):
            raise ValueError('Observation is outside the supported city')
        return self

class Decision(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal['verified', 'rejected']
    reason: str = Field(min_length=10, max_length=500)
    source: str = Field(min_length=3, max_length=200)
    expires_in_hours: int = Field(ge=1, le=168)

class HazardStore:
    def __init__(self, path: str | None = None):
        self.path = path or os.getenv('SAQGO_DATA_FILE', '.local/saqgo.sqlite3')
    def connection(self):
        Path(self.path).parent.mkdir(parents=True, exist_ok=True)
        db = sqlite3.connect(self.path)
        db.row_factory = sqlite3.Row
        db.executescript('''
          CREATE TABLE IF NOT EXISTS observations (
            id TEXT PRIMARY KEY, event_key TEXT UNIQUE NOT NULL,
            latitude REAL, longitude REAL, category TEXT,
            confidence REAL, accuracy_meters REAL, observed_at TEXT,
            status TEXT DEFAULT 'pending', source TEXT DEFAULT 'user_observation',
            updated_at REAL, expires_at REAL);
          CREATE TABLE IF NOT EXISTS audit (
            id INTEGER PRIMARY KEY, observation_id TEXT, actor TEXT,
            decision TEXT, reason TEXT, source TEXT, created_at REAL);
        ''')
        return db
    def submit(self, observation: Observation, event_key: str):
        # ~100 m cell; omit the exact input coordinates, track and user identity.
        point = observation.point
        with self.connection() as db:
            existing = db.execute('SELECT id FROM observations WHERE event_key=?', (event_key,)).fetchone()
            if existing: return existing['id'], False
            identifier = str(uuid.uuid4())
            db.execute('INSERT INTO observations (id,event_key,latitude,longitude,category,confidence,accuracy_meters,observed_at,updated_at,expires_at) VALUES (?,?,?,?,?,?,?,?,?,?)',
                       (identifier, event_key, round(point.latitude,3), round(point.longitude,3), observation.category, observation.confidence, observation.accuracy_meters, observation.observed_at, time.time(), time.time()+86400))
            return identifier, True
    def list(self, *, public: bool, offset: int = 0):
        with self.connection() as db:
            db.execute('DELETE FROM observations WHERE status="pending" AND expires_at < ?', (time.time(),))
            where = 'WHERE status="verified" AND expires_at > ?' if public else ''
            params = (time.time(), offset) if public else (offset,)
            rows = db.execute(f'SELECT * FROM observations {where} ORDER BY updated_at DESC LIMIT 100 OFFSET ?', params).fetchall()
        return [self.feature(dict(row)) for row in rows]
    @staticmethod
    def feature(row):
        return {'type':'Feature', 'id':row['id'],
                'geometry':{'type':'Point','coordinates':[row['longitude'],row['latitude']]},
                'properties':{key:row[key] for key in ('category','confidence','accuracy_meters','observed_at','status','source','updated_at','expires_at')} | {'demo':False}}
    def decide(self, identifier: str, decision: Decision, actor: str):
        with self.connection() as db:
            exists = db.execute('SELECT id FROM observations WHERE id=?', (identifier,)).fetchone()
            if not exists: return False
            db.execute('UPDATE observations SET status=?,source=?,updated_at=?,expires_at=? WHERE id=?',
                       (decision.status, decision.source, time.time(), time.time()+decision.expires_in_hours*3600, identifier))
            db.execute('INSERT INTO audit (observation_id,actor,decision,reason,source,created_at) VALUES (?,?,?,?,?,?)',
                       (identifier, actor, decision.status, decision.reason, decision.source, time.time()))
            return True
    def audit(self):
        with self.connection() as db:
            return [dict(row) for row in db.execute('SELECT * FROM audit ORDER BY id DESC LIMIT 100')]

DEMO_FEATURES = [{'type':'Feature','id':'demo-road-bump',
 'geometry':{'type':'Point','coordinates':[66.922,50.250]},
 'properties':{'category':'road_bump','confidence':0.4,'accuracy_meters':100,'observed_at':None,
 'status':'unverified','source':'synthetic_fixture','updated_at':None,'expires_at':None,'demo':True}}]
