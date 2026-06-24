import logging

from app.core.geocoding import GeocodingService
from app.core.llm import LLMService
from app.models.intent import RideIntent
from app.prompts.system_prompt import build_messages

logger = logging.getLogger(__name__)


class IntentParser:
    """Orchestrates intent parsing: LLM extraction + address geocoding.

    Flow:
    1. Build system prompt + user messages
    2. Call LLM to extract structured intent
    3. Resolve pickup/dropoff addresses to coordinates via AMap API
    """

    def __init__(self, llm: LLMService, geocoding: GeocodingService) -> None:
        self.llm = llm
        self.geocoding = geocoding

    async def parse(self, text: str, history: list[dict[str, str]] | None = None) -> tuple[RideIntent, str]:
        """Parse user input to extract ride-hailing intent.

        Args:
            text: User input text (after ASR if voice).
            history: Previous conversation messages.

        Returns:
            Tuple of (RideIntent, raw_response_text).
        """
        messages = build_messages(text, history)
        raw_response = await self.llm.chat(messages)
        intent = await self.llm.parse_intent(raw_response)

        # Resolve addresses if intent is ride_booking
        if intent.intent_type == "ride_booking":
            await self.geocoding.resolve_intent_addresses(intent.pickup, intent.dropoff)

        return intent, raw_response
