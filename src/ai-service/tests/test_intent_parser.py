"""Tests for intent parser module.

These tests validate structured output parsing from LLM responses.
Run with: pytest tests/test_intent_parser.py -v
"""
import pytest

from app.models.intent import AddressInfo, IntentType, RideIntent


class TestRideIntent:
    def test_valid_ride_intent(self):
        intent = RideIntent(
            intent_type=IntentType.RIDE_BOOKING,
            pickup=AddressInfo(address="望京SOHO"),
            dropoff=AddressInfo(address="中关村软件园"),
            car_type=1,
        )
        assert intent.intent_type == IntentType.RIDE_BOOKING
        assert intent.pickup.address == "望京SOHO"
        assert intent.dropoff.address == "中关村软件园"
        assert intent.car_type == 1
        assert intent.missing_fields == []

    def test_incomplete_intent(self):
        intent = RideIntent(
            intent_type=IntentType.RIDE_BOOKING,
            pickup=AddressInfo(address="北京西站"),
            missing_fields=["dropoff"],
        )
        assert intent.dropoff is None
        assert "dropoff" in intent.missing_fields

    def test_greeting_intent(self):
        intent = RideIntent(
            intent_type=IntentType.GREETING,
        )
        assert intent.intent_type == IntentType.GREETING
        assert intent.pickup is None
        assert intent.dropoff is None
