import logging

from fastapi import APIRouter, Depends

from app.dependencies import get_chat_service
from app.models.chat import ChatRequest, ChatResponse
from app.services.chat_service import ChatService

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
async def chat(
    req: ChatRequest,
    svc: ChatService = Depends(get_chat_service),
) -> ChatResponse:
    """Process a chat message (text or voice).

    Go backend sends passenger input here. Returns structured intent
    and a natural-language response for the passenger.
    """
    logger.info("chat request: session=%s user=%d text=%s", req.session_id, req.user_id, req.text[:80] if req.text else "(voice)")
    resp = await svc.process(req)
    return resp
