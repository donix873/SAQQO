from __future__ import annotations

import logging
import time
import uuid
from collections import defaultdict, deque
from datetime import UTC, datetime

from fastapi import FastAPI, HTTPException, Request, Depends, Header, Query
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from .hazards import HazardStore, Observation, Decision, DEMO_FEATURES
from .admin_auth import Login, login, moderator
from .config import Settings
from .models import (
    ApiError,
    ApiErrorBody,
    CapabilitiesResponse,
    DistanceMatrixRequest,
    GeocodeResponse,
    HealthResponse,
    RouteRequest,
)
from .yandex import UpstreamUnavailable, YandexGateway

# Uvicorn default access logs contain address queries. Disable at the source.
logging.getLogger("uvicorn.access").disabled = True
settings = Settings.from_environment()
gateway = YandexGateway(settings)
app = FastAPI(title="SAQGO API", version="v1", docs_url=None, redoc_url=None)

if settings.allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.allowed_origins),
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type", "Accept-Language", "Idempotency-Key"],
    )

_requests: dict[str, deque[float]] = defaultdict(deque)


def problem(status: int, code: str, message: str, request_id: str) -> JSONResponse:
    return JSONResponse(
        status_code=status,
        headers={"X-Request-ID": request_id, "Cache-Control": "no-store"},
        content=ApiError(
            error=ApiErrorBody(code=code, message=message, request_id=request_id)
        ).model_dump(),
    )


@app.middleware("http")
async def privacy_and_rate_limit(request: Request, call_next):
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id
    content_length=request.headers.get("Content-Length")
    if content_length and (not content_length.isdigit() or int(content_length)>32768):
        return problem(413,"payload_too_large","Request is too large.",request_id)
    # No URL/body logging: these can contain a user's coordinates or address.
    if request.url.path.startswith('/v1/'):
        client = request.client.host if request.client else "unknown"
        now = time.monotonic()
        for key, queue in list(_requests.items()):
            if not queue or queue[-1] <= now - 60:
                _requests.pop(key, None)
        if client not in _requests and len(_requests) >= 10000:
            return problem(429, "rate_limited", "Too many clients.", request_id)
        recent = _requests[client]
        while recent and recent[0] <= now - 60:
            recent.popleft()
        if len(recent) >= 30:
            return problem(429, "rate_limited", "Too many requests.", request_id)
        recent.append(now)
    response = await call_next(request)
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Request-ID"] = request_id
    return response


@app.exception_handler(UpstreamUnavailable)
async def upstream_unavailable(request: Request, error: UpstreamUnavailable):
    return problem(
        503,
        "provider_unavailable",
        str(error),
        getattr(request.state, "request_id", str(uuid.uuid4())),
    )


@app.exception_handler(StarletteHTTPException)
async def http_error(request: Request, error: StarletteHTTPException):
    messages = {
        400: "The request is invalid.",
        404: "The endpoint was not found.",
        405: "The method is not allowed.",
    }
    return problem(
        error.status_code,
        "request_error",
        messages.get(error.status_code, "The request could not be completed."),
        getattr(request.state, "request_id", str(uuid.uuid4())),
    )


@app.exception_handler(RequestValidationError)
async def validation_error(request: Request, _: RequestValidationError):
    # Do not echo invalid coordinates or raw addresses back into logs/responses.
    return problem(
        400,
        "validation_error",
        "The request format is invalid.",
        getattr(request.state, "request_id", str(uuid.uuid4())),
    )


@app.get("/v1/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(time=datetime.now(UTC).isoformat())


@app.get("/v1/capabilities", response_model=CapabilitiesResponse)
async def capabilities() -> CapabilitiesResponse:
    return CapabilitiesResponse(
        environment=settings.environment,
        geocoding=settings.geocoder_key is not None,
        routing=settings.route_details_key is not None,
        distance_matrix=settings.distance_matrix_key is not None,
        isochrone=settings.isochrone_key is not None,
    )


@app.get("/v1/places", response_model=GeocodeResponse, responses={503: {"model": ApiError}})
async def places(query: str) -> GeocodeResponse:
    normalized = query.strip()
    if not 2 <= len(normalized) <= 120:
        raise HTTPException(status_code=400, detail="Query must contain 2 to 120 characters.")
    return GeocodeResponse(query=normalized, results=await gateway.geocode(normalized))


@app.post("/v1/routes", responses={503: {"model": ApiError}})
async def route(request: RouteRequest) -> dict:
    return await gateway.route_details(request.origin, request.destination, request.mode)


@app.post("/v1/distance-matrix", responses={503: {"model": ApiError}})
async def distance_matrix(request: DistanceMatrixRequest) -> dict:
    return await gateway.distance_matrix(
        request.origins, request.destinations, request.mode
    )



hazard_store = HazardStore()

@app.get('/v1/config')
async def configuration():
    return {'version':'1.3','city_id':'arqalyk','provider':'yandex',
            'maximum_accuracy_meters':65,'alert_cooldown_seconds':300,
            'alert_distance_meters':100,'risk_coverage':'unknown'}

@app.get('/v1/hazards')
async def hazards(demo: bool = False, offset: int = Query(0, ge=0, le=10000)):
    features = DEMO_FEATURES if demo else hazard_store.list(public=True, offset=offset)
    return {'type':'FeatureCollection','features':features,'coverage':'unknown','demo':demo}

@app.post('/v1/observations')
async def observation(body: Observation, idempotency_key: str = Header(alias='Idempotency-Key')):
    try:
        uuid.UUID(idempotency_key)
    except ValueError:
        raise HTTPException(400, 'Idempotency key must be a UUID')
    identifier, created = hazard_store.submit(body, idempotency_key)
    return JSONResponse({'id':identifier,'status':'pending_validation'},status_code=201 if created else 200)

@app.post('/v1/admin/login')
async def admin_login(body: Login, request: Request):
    if settings.environment == "production" and request.url.scheme != "https":
        raise HTTPException(403, "HTTPS is required")
    return login(body)

@app.get('/v1/admin/observations')
async def moderation_queue(actor: str = Depends(moderator), offset: int = Query(0, ge=0, le=10000)):
    return {'features':hazard_store.list(public=False,offset=offset)}

@app.post('/v1/admin/observations/{identifier}')
async def moderation_decision(identifier: str, body: Decision, actor: str = Depends(moderator)):
    if not hazard_store.decide(identifier,body,actor):raise HTTPException(404,'Observation not found')
    return {'status':body.status}

@app.get('/v1/admin/audit')
async def moderation_audit(actor: str = Depends(moderator)):
    return {'actions':hazard_store.audit()}

@app.get('/admin', include_in_schema=False)
async def admin_console():
    from pathlib import Path
    from fastapi.responses import FileResponse
    return FileResponse(Path(__file__).resolve().parents[1] / 'admin.html', headers={'Cache-Control':'no-store','X-Frame-Options':'DENY','Content-Security-Policy':"default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'"})


# Optional same-origin presentation client, after all API routes.
import os
from fastapi.staticfiles import StaticFiles
if web_directory := os.getenv('SAQGO_WEB_DIR'):
    app.mount(os.getenv('SAQGO_WEB_PATH','/'), StaticFiles(directory=web_directory, html=True), name='presentation')
