import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.main import app  # noqa: E402


client = TestClient(app)


def test_health_has_no_personal_data() -> None:
    response = client.get("/v1/health")

    assert response.status_code == 200
    assert response.json()["service"] == "saqgo-api"
    assert response.headers["x-request-id"]


def test_invalid_query_uses_api_error_contract() -> None:
    response = client.get("/v1/places", params={"query": "a"})

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "request_error"
    assert response.headers["x-request-id"]


def test_route_requires_configured_provider() -> None:
    response = client.post(
        "/v1/routes",
        json={
            "origin": {"latitude": 50.25, "longitude": 66.92},
            "destination": {"latitude": 50.26, "longitude": 66.93},
        },
    )

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "provider_unavailable"
