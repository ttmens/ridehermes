"""Tests for geocoding module.

Run with: pytest tests/test_geocoding.py -v
"""
import pytest


class TestGeocodingService:
    def test_address_info_unresolved(self):
        from app.models.intent import AddressInfo

        info = AddressInfo(address="测试地址")
        assert info.resolved is False
        assert info.lat is None
        assert info.lng is None

    def test_address_info_resolved(self):
        from app.models.intent import AddressInfo

        info = AddressInfo(
            address="望京SOHO",
            lat=39.9950,
            lng=116.4770,
            resolved=True,
        )
        assert info.resolved is True
        assert info.lat == 39.9950
        assert info.lng == 116.4770
