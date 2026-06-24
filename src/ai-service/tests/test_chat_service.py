"""Tests for chat service orchestration.

Run with: pytest tests/test_chat_service.py -v
"""
import pytest


class TestChatService:
    def test_response_text_extraction(self):
        from app.services.chat_service import ChatService
        from app.models.intent import IntentType, RideIntent

        svc = ChatService
        intent = RideIntent(intent_type=IntentType.OTHER)

        # JSON with response_text
        result = svc._extract_response_text(
            '{"response_text": "hello world"}',
            intent,
        )
        assert result == "hello world"

        # Plain text fallback
        result = svc._extract_response_text("hello world", intent)
        assert result == "hello world"

        # Markdown code fence
        result = svc._extract_response_text(
            '```json\n{"response_text": "hi"}\n```',
            intent,
        )
        assert result == "hi"
