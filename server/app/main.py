from __future__ import annotations

import time
import uuid
from collections import defaultdict, deque
from datetime import UTC, datetime

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

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
        content=ApiError(
            error=ApiErrorBody(code=code, message=message, request_id=request_id)
        ).model_dump(),
    )


@app.middleware("http")
async def privacy_and_rate_limit(request: Request, call_next):
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id
    # No URL/body logging: these can contain a user's coordinates or address.
    client = request.client.host if request.client else "unknown"
    now = time.monotonic()
    recent = _requests[client]
    while recent and recent[0] <= now - 60:
        recent.popleft()
    if len(recent) >= 30:
        return problem(429, "rate_limited", "Too many requests.", request_id)
    recent.append(now)
    response = await call_next(request)
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

