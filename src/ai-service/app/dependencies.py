import redis.asyncio as redis

from app.config import settings
from app.core.asr import ASRService
from app.services.chat_service import ChatService


_redis_client: redis.Redis | None = None
_chat_service: ChatService | None = None
_asr_service: ASRService | None = None


async def get_redis() -> redis.Redis:
    global _redis_client
    if _redis_client is None:
        _redis_client = redis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
        )
    return _redis_client


async def get_asr_service() -> ASRService:
    global _asr_service
    if _asr_service is None:
        _asr_service = ASRService()
    return _asr_service


async def get_chat_service() -> ChatService:
    global _chat_service
    if _chat_service is None:
        rdb = await get_redis()
        _chat_service = ChatService(rdb)
    return _chat_service
