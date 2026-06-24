import json
import time
import logging

import redis.asyncio as redis

from app.config import settings

logger = logging.getLogger(__name__)

SESSION_TTL = 3600  # 1 hour
MAX_MESSAGES = settings.redis_max_history  # 20


class ContextManager:
    """Manages conversation context stored in Redis.

    Each session is stored as a Redis hash with:
    - session_id, user_id, messages (JSON), created_at, updated_at
    """

    def __init__(self, rdb: redis.Redis) -> None:
        self.rdb = rdb

    def _key(self, session_id: str) -> str:
        return f"ai:session:{session_id}"

    async def get_history(self, session_id: str) -> list[dict[str, str]]:
        """Get recent conversation history for a session."""
        key = self._key(session_id)
        data = await self.rdb.hget(key, "messages")
        if data:
            messages = json.loads(data)
            return [{"role": m["role"], "content": m["content"]} for m in messages[-MAX_MESSAGES:]]
        return []

    async def append(self, session_id: str, user_id: int, role: str, content: str) -> None:
        """Append a message to the session history."""
        key = self._key(session_id)
        exists = await self.rdb.exists(key)

        msg = {
            "role": role,
            "content": content,
            "timestamp": time.time(),
        }

        if not exists:
            await self.rdb.hset(key, mapping={
                "session_id": session_id,
                "user_id": str(user_id),
                "messages": json.dumps([msg], ensure_ascii=False),
                "created_at": str(time.time()),
                "updated_at": str(time.time()),
            })
        else:
            messages_data = await self.rdb.hget(key, "messages")
            messages = json.loads(messages_data) if messages_data else []
            messages.append(msg)
            # Trim to max
            if len(messages) > MAX_MESSAGES:
                messages = messages[-MAX_MESSAGES:]
            await self.rdb.hset(key, "messages", json.dumps(messages, ensure_ascii=False))
            await self.rdb.hset(key, "updated_at", str(time.time()))

        await self.rdb.expire(key, SESSION_TTL)
