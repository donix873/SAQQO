from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    environment: str
    allowed_origins: tuple[str, ...]
    geocoder_key: str | None
    route_details_key: str | None
    distance_matrix_key: str | None
    isochrone_key: str | None
    route_details_url: str
    distance_matrix_url: str

    @classmethod
    def from_environment(cls) -> "Settings":
        origins = tuple(
            origin.strip()
            for origin in os.getenv("SAQGO_ALLOWED_ORIGINS", "").split(",")
            if origin.strip()
        )
        return cls(
            environment=os.getenv("SAQGO_ENV", "development"),
            allowed_origins=origins,
            geocoder_key=os.getenv("YANDEX_GEOCODER_API_KEY") or None,
            route_details_key=os.getenv("YANDEX_ROUTE_DETAILS_API_KEY") or None,
            distance_matrix_key=os.getenv("YANDEX_DISTANCE_MATRIX_API_KEY") or None,
            isochrone_key=os.getenv("YANDEX_ISOCHRONE_API_KEY") or None,
            route_details_url=os.getenv(
                "YANDEX_ROUTE_DETAILS_URL", "https://api.routing.yandex.net/v2/route"
            ),
            distance_matrix_url=os.getenv(
                "YANDEX_DISTANCE_MATRIX_URL",
                "https://api.routing.yandex.net/v2/distancematrix",
            ),
        )

