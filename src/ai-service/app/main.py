import logging

from contextlib import asynccontextmanager
from fastapi import FastAPI

from app.api.router import api_router
from app.dependencies import get_asr_service
from app.models.chat import HealthResponse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

VERSION = "0.1.0"


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        asr = await get_asr_service()
        await asr.initialize()
    except Exception as e:
        logger.warning("ASR initialization failed (voice input will be unavailable): %s", e)
    yield


app = FastAPI(
    title="RideHermes AI Service",
    description="AI Agent service for ride-hailing intent parsing and voice recognition",
    version=VERSION,
    lifespan=lifespan,
)

app.include_router(api_router)


@app.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    """Health check endpoint."""
    from app.dependencies import get_asr_service
    asr = await get_asr_service()
    return HealthResponse(
        status="ok",
        version=VERSION,
        llm_available=True,
        asr_available=asr.is_available(),
    )
