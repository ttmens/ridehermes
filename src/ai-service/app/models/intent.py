from enum import StrEnum

from pydantic import BaseModel, Field


class IntentType(StrEnum):
    RIDE_BOOKING = "ride_booking"
    RIDE_CANCEL = "ride_cancel"
    GREETING = "greeting"
    UNCLEAR = "unclear"
    OTHER = "other"


class AddressInfo(BaseModel):
    """Address information with optional resolved coordinates."""
    address: str = Field(..., description="Address text (e.g., 望京SOHO)")
    lat: float | None = Field(None, description="Latitude")
    lng: float | None = Field(None, description="Longitude")
    resolved: bool = Field(False, description="Whether coordinates have been resolved")


class RideIntent(BaseModel):
    """Ride-hailing intent extracted from user input."""
    intent_type: IntentType = Field(..., description="Intent type")
    pickup: AddressInfo | None = Field(None, description="Pickup point")
    dropoff: AddressInfo | None = Field(None, description="Dropoff point")
    car_type: int | None = Field(None, description="Car type: 1=economy 2=comfort 3=luxury")
    departure_time: str | None = Field(None, description="Departure time in ISO 8601 format")
    departure_desc: str | None = Field(None, description="Original user description of departure time")
    missing_fields: list[str] = Field(
        default_factory=list,
        description="Missing required fields, e.g., ['pickup', 'car_type', 'departure_time']",
    )
