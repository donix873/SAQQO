import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.main import app  # noqa: E402
from app.models import Point, compact_points  # noqa: E402


client = TestClient(app)


def test_health_has_no_personal_data() -> None:
    response = client.get("/v1/health")

    assert response.status_code == 200
    assert response.json()["service"] == "saqgo-api"
    assert response.headers["x-request-id"]


def test_capabilities_expose_flags_but_never_keys() -> None:
    response = client.get("/v1/capabilities")

    assert response.status_code == 200
    body = response.json()
    assert body["service"] == "saqgo-api"
    assert isinstance(body["geocoding"], bool)
    assert isinstance(body["routing"], bool)
    assert isinstance(body["distance_matrix"], bool)
    assert "key" not in response.text.lower()
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


def test_router_coordinates_use_latitude_longitude_order() -> None:
    points = [
        Point(latitude=50.25, longitude=66.92),
        Point(latitude=50.26, longitude=66.93),
    ]

    assert compact_points(points) == "50.25,66.92|50.26,66.93"


def test_static_asset_requests_do_not_exhaust_api_rate_limit():
    from app.main import _requests
    _requests.clear()
    for _ in range(40):
        assert client.get('/presentation-unavailable-file').status_code == 404
    assert client.get('/v1/health').status_code == 200
    _requests.clear()
