from __future__ import annotations

from typing import Any

import httpx

from .config import Settings
from .models import Place, Point, compact_points


class UpstreamUnavailable(Exception):
    pass


class YandexGateway:
    """Keeps provider keys and coordinate-bearing requests on the server."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def geocode(self, query: str) -> list[Place]:
        if not self._settings.geocoder_key:
            raise UpstreamUnavailable("Geocoding is not configured.")
        params = {
            "apikey": self._settings.geocoder_key,
            "geocode": query if any(city in query.lower() for city in ("аркалык","арқалық","arkalyk")) else f"{query}, Аркалык, Казахстан",
            "format": "json",
            "results": "5",
            "lang": "ru_RU",
            "bbox": "66.45,50.05~67.38,50.48",
            "rspn": "1",
        }
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(
                    "https://geocode-maps.yandex.ru/v1/", params=params
                )
                response.raise_for_status()
        except httpx.HTTPError as error:
            raise UpstreamUnavailable("Geocoding provider is unavailable.") from error

        try:
            members = response.json()["response"]["GeoObjectCollection"].get("featureMember", [])
        except (ValueError, KeyError, TypeError):
            raise UpstreamUnavailable("Geocoding provider returned invalid data.")
        results: list[Place] = []
        for member in members:
            geo_object = member.get("GeoObject", {})
            position = geo_object.get("Point", {}).get("pos", "").split()
            if len(position) != 2:
                continue
            try:
                longitude, latitude = map(float, position)
            except ValueError:
                continue
            if not (50.05 <= latitude <= 50.48 and 66.45 <= longitude <= 67.38):
                continue
            meta = geo_object.get("metaDataProperty", {}).get(
                "GeocoderMetaData", {}
            )
            results.append(
                Place(
                    name=meta.get("text") or geo_object.get("name", "Аркалык"),
                    address=meta.get("Address", {}).get("formatted")
                    or geo_object.get("description", ""),
                    point=Point(latitude=latitude, longitude=longitude),
                )
            )
        return results

    async def route_details(
        self, origin: Point, destination: Point, mode: str
    ) -> dict[str, Any]:
        if not self._settings.route_details_key:
            raise UpstreamUnavailable("Route details are not configured.")
        return await self._request_routing(
            self._settings.route_details_url,
            self._settings.route_details_key,
            {"waypoints": compact_points([origin, destination]), "mode": mode},
        )

    async def distance_matrix(
        self, origins: list[Point], destinations: list[Point], mode: str
    ) -> dict[str, Any]:
        if not self._settings.distance_matrix_key:
            raise UpstreamUnavailable("Distance matrix is not configured.")
        return await self._request_routing(
            self._settings.distance_matrix_url,
            self._settings.distance_matrix_key,
            {
                "origins": compact_points(origins),
                "destinations": compact_points(destinations),
                "mode": mode,
            },
        )

    async def _request_routing(
        self, url: str, api_key: str, params: dict[str, str]
    ) -> dict[str, Any]:
        try:
            async with httpx.AsyncClient(timeout=12) as client:
                response = await client.get(url, params={**params, "apikey": api_key})
                response.raise_for_status()
                return response.json()
        except (httpx.HTTPError, ValueError) as error:
            raise UpstreamUnavailable("Routing provider is unavailable.") from error

