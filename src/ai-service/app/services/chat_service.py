import json
import logging
import re

import redis.asyncio as redis

from app.context.manager import ContextManager
from app.core.asr import ASRError, ASRService
from app.core.geocoding import GeocodingService
from app.core.intent_parser import IntentParser
from app.core.llm import LLMError, LLMService
from app.models.chat import ChatRequest, ChatResponse
from app.models.intent import AddressInfo, IntentType, RideIntent

logger = logging.getLogger(__name__)


class ChatService:
    """Main chat service orchestrating ASR → Intent Parsing → Geocoding."""

    def __init__(self, rdb: redis.Redis) -> None:
        self.context = ContextManager(rdb)
        self.asr = ASRService()
        self.llm = LLMService()
        self.geocoding = GeocodingService()
        self.intent_parser = IntentParser(self.llm, self.geocoding)

    async def process(self, req: ChatRequest) -> ChatResponse:
        """Process a chat request end-to-end.

        Flow:
        1. If voice input, run ASR to get text
        2. Get conversation history from Redis
        3. Parse intent via LLM
        4. Resolve addresses via AMap geocoding
        5. Save conversation to Redis
        6. Return structured response
        """
        session_id = req.session_id
        user_id = req.user_id

        # Step 1: Determine input text (ASR or direct text)
        text = req.text
        asr_text = None
        if req.audio_base64:
            if not self.asr.is_available():
                await self.asr.initialize()
            try:
                text = await self.asr.transcribe(req.audio_base64)
                asr_text = text
            except ASRError as e:
                logger.warning("ASR failed: %s", e)
                return ChatResponse(
                    session_id=session_id,
                    response_text="抱歉，语音识别失败，请尝试用文字输入。",
                    intent=RideIntent(
                        intent_type=IntentType.OTHER,
                    ),
                    asr_text=None,
                )

        if not text or not text.strip():
            return ChatResponse(
                session_id=session_id,
                response_text="请输入您的出行需求，例如：我要从望京SOHO去中关村软件园。",
                intent=RideIntent(
                    intent_type=IntentType.UNCLEAR,
                    missing_fields=["pickup", "dropoff"],
                ),
            )

        # Save user message to history
        await self.context.append(session_id, user_id, "user", text)

        # Step 2: Get history
        history = req.history or await self.context.get_history(session_id)

        # Step 3-4: Parse intent + resolve addresses
        try:
            intent, raw_response = await self.intent_parser.parse(text, history)
        except LLMError as e:
            logger.error("LLM invocation failed: %s", e)
            # Fallback: return a basic response without LLM
            intent = RideIntent(
                intent_type=IntentType.OTHER,
                missing_fields=["pickup", "dropoff"],
            )
            raw_response = "抱歉，AI服务暂时不可用，请稍后再试。"

        # Extract the response_text from raw LLM output if we have a JSON response
        response_text = self._extract_response_text(raw_response, intent)

        # Step 5: Save AI response to history
        await self.context.append(session_id, user_id, "assistant", response_text)

        # Step 6: Build response
        return ChatResponse(
            session_id=session_id,
            response_text=response_text,
            intent=intent,
            asr_text=asr_text,
        )

    @staticmethod
    def _extract_response_text(raw: str, intent: RideIntent) -> str:
        """Extract the user-facing response_text from raw LLM output."""
        cleaned = raw.strip()

        # Try extracting from markdown code fences first
        fence_match = re.search(r'```(?:json)?\s*\n(.*?)\n```', cleaned, re.DOTALL)
        if fence_match:
            cleaned = fence_match.group(1).strip()

        # Try to find JSON block in the text
        if not cleaned.startswith('{'):
            match = re.search(r'\{.*\}', cleaned, re.DOTALL)
            if match:
                cleaned = match.group(0).strip()

        try:
            data = json.loads(cleaned)
            return data.get("response_text", raw)
        except (json.JSONDecodeError, TypeError):
            pass

        # If not JSON, return the raw text as-is
        return raw
