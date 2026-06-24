import json
import logging

from openai import AsyncOpenAI

from app.config import settings
from app.models.intent import AddressInfo, IntentType, RideIntent

logger = logging.getLogger(__name__)


class LLMError(Exception):
    """Raised when LLM invocation fails."""
    pass


class LLMService:
    """LLM invocation via OpenAI-compatible API.

    Supports: Qwen2.5-72B-Instruct (DashScope), DeepSeek-V3, GPT-4o.
    """

    def __init__(self) -> None:
        self.client = AsyncOpenAI(
            base_url=settings.llm_base_url,
            api_key=settings.llm_api_key,
            timeout=settings.llm_timeout,
        )
        self.model = settings.llm_model
        self.max_tokens = settings.llm_max_tokens
        self.temperature = settings.llm_temperature

    async def chat(self, messages: list[dict[str, str]]) -> str:
        """Send messages to LLM and return response text.

        Args:
            messages: List of {"role": "user"|"assistant"|"system", "content": "..."}.

        Returns:
            LLM response text.

        Raises:
            LLMError: If the API call fails.
        """
        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=self.temperature,
                max_tokens=self.max_tokens,
            )
            msg = response.choices[0].message
            content = msg.content
            # DeepSeek reasoning models (v4-flash, r1, etc.) may put output in
            # reasoning_content and leave content empty when max_tokens is hit.
            if not content:
                reasoning = getattr(msg, "reasoning_content", None)
                if reasoning:
                    return reasoning
            return content or ""
        except Exception as e:
            logger.error("LLM call failed: %s", e)
            raise LLMError(f"LLM service error: {e}") from e

    async def parse_intent(self, raw: str) -> RideIntent:
        """Parse LLM response to extract ride-hailing intent.

        Expects the LLM response to be a JSON block with the intent structure.
        Falls back to a greeting intent if parsing fails.
        """
        try:
            data = self._extract_json(raw)
            return RideIntent(
                intent_type=IntentType(data.get("intent_type", "other")),
                pickup=AddressInfo(**data["pickup"]) if data.get("pickup") else None,
                dropoff=AddressInfo(**data["dropoff"]) if data.get("dropoff") else None,
                car_type=data.get("car_type"),
                departure_time=data.get("departure_time"),
                departure_desc=data.get("departure_desc"),
                missing_fields=data.get("missing_fields", []),
            )
        except (json.JSONDecodeError, KeyError, TypeError) as e:
            logger.warning("Failed to parse LLM intent JSON: %s, raw=%s", e, raw)
            return RideIntent(
                intent_type=IntentType.OTHER,
                missing_fields=["pickup", "dropoff"],
            )

    def is_available(self) -> bool:
        return bool(settings.llm_api_key)

    @staticmethod
    def _extract_json(raw: str) -> dict:
        """Extract JSON from LLM response, handling markdown code fences and text before/after JSON."""
        import re
        raw = raw.strip()

        # Try extracting from markdown code fences first
        fence_match = re.search(r'```(?:json)?\s*\n(.*?)\n```', raw, re.DOTALL)
        if fence_match:
            raw = fence_match.group(1).strip()

        # If still not JSON, find the outermost { } or [ ] block
        raw_stripped = raw.strip()
        if not raw_stripped.startswith(('{', '[')):
            match = re.search(r'(\{.*\}|\[.*\])', raw, re.DOTALL)
            if match:
                raw = match.group(1).strip()
            else:
                raw = raw_stripped

        return json.loads(raw)
