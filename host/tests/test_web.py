"""Unit tests for web endpoints — no real BLE."""

import pytest
from fastapi import HTTPException

from lamp_client import web as web_module
from lamp_client.ble import LampState


class FakeLamp:
    def __init__(self):
        self.calls: list[LampState] = []

    async def set_state(self, state: LampState) -> None:
        self.calls.append(state)


@pytest.fixture
def fake_lamp(monkeypatch):
    lamp = FakeLamp()
    monkeypatch.setattr(web_module, "_lamp", lamp)
    return lamp


@pytest.fixture
def disconnected(monkeypatch):
    monkeypatch.setattr(web_module, "_lamp", None)


async def test_lamp_on_writes_white_full_brightness(fake_lamp):
    result = await web_module.lamp_on()
    assert result["ok"] is True
    assert fake_lamp.calls == [LampState(True, 255, 255, 255, 100)]


async def test_lamp_off_writes_all_zeros(fake_lamp):
    result = await web_module.lamp_off()
    assert result["ok"] is True
    assert fake_lamp.calls == [LampState(False, 0, 0, 0, 0)]


async def test_lamp_on_503_when_disconnected(disconnected):
    with pytest.raises(HTTPException) as exc:
        await web_module.lamp_on()
    assert exc.value.status_code == 503


async def test_lamp_off_503_when_disconnected(disconnected):
    with pytest.raises(HTTPException) as exc:
        await web_module.lamp_off()
    assert exc.value.status_code == 503


async def test_set_state_503_when_disconnected(disconnected):
    req = web_module.StateRequest(power=True, r=128, g=64, b=32, brightness=50)
    with pytest.raises(HTTPException) as exc:
        await web_module.set_state(req)
    assert exc.value.status_code == 503


async def test_response_state_echoes_applied_values(fake_lamp):
    result = await web_module.lamp_on()
    assert result["state"] == {
        "power": True, "r": 255, "g": 255, "b": 255, "brightness": 100,
    }
