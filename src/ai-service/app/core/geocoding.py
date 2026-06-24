import asyncio
import logging

import httpx

from app.config import settings
from app.models.intent import AddressInfo

logger = logging.getLogger(__name__)


class GeocodingError(Exception):
    """Raised when geocoding fails."""
    pass


class GeocodingService:
    """Address resolution using AMap (高德) Geocoding API.

    Converts natural language addresses (e.g., "望京SOHO") to lat/lng coordinates.
    """

    BASE_URL = "https://restapi.amap.com/v3/geocode/geo"

    def __init__(self) -> None:
        self.api_key = settings.amap_api_key

    async def resolve(self, address: str, city: str = "北京") -> AddressInfo:
        """Resolve an address string to coordinates.

        Args:
            address: Address text to resolve.
            city: City hint to narrow search scope.

        Returns:
            AddressInfo with resolved coordinates.

        Raises:
            GeocodingError: If the API call fails.
        """
        if not self.api_key:
            logger.warning("AMap API key not configured, returning unresolved address")
            return AddressInfo(address=address, lat=None, lng=None, resolved=False)

        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(
                    self.BASE_URL,
                    params={
                        "key": self.api_key,
                        "address": address,
                        "city": city,
                        "output": "JSON",
                    },
                )
                resp.raise_for_status()
                data = resp.json()

            if data.get("status") == "1" and data.get("geocodes"):
                geocode = data["geocodes"][0]
                location = geocode.get("location", "")
                if location and "," in location:
                    lng_str, lat_str = location.split(",", 1)
                    return AddressInfo(
                        address=address,
                        lat=float(lat_str),
                        lng=float(lng_str),
                        resolved=True,
                    )

            logger.warning("Geocoding returned no results for: %s", address)
            return AddressInfo(address=address, lat=None, lng=None, resolved=False)

        except Exception as e:
            logger.error("Geocoding failed for '%s': %s", address, e)
            return AddressInfo(address=address, lat=None, lng=None, resolved=False)

    async def resolve_intent_addresses(self, pickup: AddressInfo | None, dropoff: AddressInfo | None) -> None:
        """Resolve both pickup and dropoff addresses in parallel."""
        tasks = []
        targets = []
        if pickup and not pickup.resolved:
            tasks.append(self.resolve(pickup.address))
            targets.append(pickup)
        if dropoff and not dropoff.resolved:
            tasks.append(self.resolve(dropoff.address))
            targets.append(dropoff)

        if not tasks:
            return

        results = await asyncio.gather(*tasks, return_exceptions=True)
        for target, result in zip(targets, results):
            if isinstance(result, Exception):
                continue
            target.lat = result.lat
            target.lng = result.lng
            target.resolved = result.resolved
