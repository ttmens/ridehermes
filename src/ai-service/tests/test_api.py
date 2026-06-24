import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health(client: AsyncClient):
    resp = await client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["version"] == "0.1.0"


@pytest.mark.asyncio
async def test_chat_empty_text(client: AsyncClient):
    """Chat with empty text should return unclear intent."""
    resp = await client.post("/ai/chat", json={
        "session_id": "test-session-1",
        "user_id": 1,
        "text": "",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["intent"]["intent_type"] == "unclear"
