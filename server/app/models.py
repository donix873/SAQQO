from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator


class Point(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class RouteRequest(BaseModel):
    origin: Point
    destination: Point
    mode: Literal["driving", "walking"] = "driving"


class DistanceMatrixRequest(BaseModel):
    origins: list[Point] = Field(min_length=1, max_length=10)
    destinations: list[Point] = Field(min_length=1, max_length=10)
    mode: Literal["driving", "walking"] = "driving"


class Place(BaseModel):
    name: str
    address: str
    point: Point


class GeocodeResponse(BaseModel):
    query: str
    results: list[Place]


class ApiErrorBody(BaseModel):
    code: str
    message: str
    request_id: str


class ApiError(BaseModel):
    error: ApiErrorBody


class HealthResponse(BaseModel):
    service: str = "saqgo-api"
    version: str = "v1"
    time: str


def compact_points(points: list[Point]) -> str:
    """Yandex Router expects latitude,longitude; do not log this value."""
    return "|".join(f"{point.latitude},{point.longitude}" for point in points)

