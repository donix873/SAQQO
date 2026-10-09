import sys, time, uuid
from pathlib import Path
from datetime import datetime, timezone
import pytest
from fastapi.testclient import TestClient
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import app.main as main
from app.hazards import HazardStore
from app.admin_auth import otp_at, sessions

@pytest.fixture
def client(tmp_path,monkeypatch):
    monkeypatch.setattr(main,'hazard_store',HazardStore(str(tmp_path/'events.db')))
    main._requests.clear();sessions.clear()
    return TestClient(main.app)

def observation():
    return {'point':{'latitude':50.250456,'longitude':66.922456},'category':'road_bump','confidence':0.4,'accuracy_meters':15,'observed_at':datetime.now(timezone.utc).isoformat(),'consent_version':'1.3'}

def test_local_observation_not_public_until_moderated(client,monkeypatch):
    event_key=str(uuid.uuid4());body=observation()
    first=client.post('/v1/observations',json=body,headers={'Idempotency-Key':event_key})
    assert first.status_code==201
    assert client.post('/v1/observations',json=body,headers={'Idempotency-Key':event_key}).status_code==200
    assert client.get('/v1/hazards').json()['features']==[]
    assert client.get('/v1/admin/observations').status_code==401
    # Deliberately public, test-only authentication fixture.
    monkeypatch.setenv('SAQGO_ADMIN_PASSWORD','test-only-moderator-password')
    secret='JBSWY3DPEHPK3PXP';monkeypatch.setenv('SAQGO_ADMIN_TOTP_SECRET',secret)
    assert client.post('/v1/admin/login',json={'password':'bad','otp':'000000'}).status_code==401
    response=client.post('/v1/admin/login',json={'password':'test-only-moderator-password','otp':otp_at(secret,int(time.time()/30))})
    assert response.status_code==200
    headers={'Authorization':'Bearer '+response.json()['access_token']}
    features=client.get('/v1/admin/observations',headers=headers).json()['features']
    assert len(features)==1
    assert features[0]['geometry']['coordinates']==[66.922,50.25]
    identifier=first.json()['id']
    result=client.post('/v1/admin/observations/'+identifier,headers=headers,json={'status':'verified','reason':'Verified by external inspection','source':'test-only-inspection','expires_in_hours':1})
    assert result.status_code==200
    assert len(client.get('/v1/hazards').json()['features'])==1
    assert len(client.get('/v1/admin/audit',headers=headers).json()['actions'])==1
    sessions.clear()
    assert client.get('/v1/admin/audit',headers=headers).status_code==401

def test_bad_accuracy_city_timestamp_and_missing_consent_rejected(client):
    for field,value in [('accuracy_meters',90),('observed_at','2000-01-01T00:00:00Z'),('consent_version','none'),('point',{'latitude':0,'longitude':0})]:
        body=observation();body[field]=value
        assert client.post('/v1/observations',json=body,headers={'Idempotency-Key':str(uuid.uuid4())}).status_code==400
    assert client.post('/v1/observations',json=observation(),headers={'Idempotency-Key':'bad'}).status_code==400

def test_demo_is_explicit_and_never_verified(client):
    assert client.get('/v1/hazards').json()['features']==[]
    demo=client.get('/v1/hazards?demo=true').json()
    assert demo['demo'] is True
    assert all(f['properties']['demo'] and f['properties']['status']!='verified' for f in demo['features'])

def test_rate_limit_has_request_id(client):
    for _ in range(31):response=client.get('/v1/health')
    assert response.status_code==429
    assert response.headers['X-Request-ID']==response.json()['error']['request_id']
