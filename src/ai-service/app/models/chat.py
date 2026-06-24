from pydantic import BaseModel, Field

from app.models.intent import RideIntent


class ChatRequest(BaseModel):
    """Go backend calls AI service with this request."""
    session_id: str = Field(..., description="Session ID (UUID)")
    user_id: int = Field(..., description="User ID")
    text: str | None = Field(None, description="Text input")
    audio_base64: str | None = Field(None, description="Audio Base64 encoded")
    history: list[dict[str, str]] = Field(
        default_factory=list,
        description="Recent conversation history [{role, content}]",
    )

    model_config = {"extra": "forbid"}


class ChatResponse(BaseModel):
    """AI service response returned to Go backend."""
    session_id: str = Field(..., description="Session ID")
    response_text: str = Field(..., description="AI response text")
    intent: RideIntent | None = Field(None, description="Parsed intent")
    asr_text: str | None = Field(None, description="ASR transcribed text (voice input only)")


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "ok"
    version: str
    llm_available: bool
    asr_available: bool
