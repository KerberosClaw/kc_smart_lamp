"""FastAPI web server: `smart-lamp-web` console script.

Endpoints:
  POST /api/set_state    — full power/RGB/brightness control (UI uses this)
  POST /api/lamp/on      — convenience: white at full brightness
  POST /api/lamp/off     — convenience: power off

The lamp connection runs in a background task with exponential backoff
auto-reconnect — see ADR 0006.
"""

from __future__ import annotations

import asyncio
import logging
import os
import threading
import webbrowser
from contextlib import asynccontextmanager
from pathlib import Path

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

from .ble import LampClient, LampNotFoundError, LampState

LOGGER = logging.getLogger(__name__)

_lamp: LampClient | None = None
_lamp_lock = asyncio.Lock()

_INITIAL_BACKOFF_SEC = 2.0
_MAX_BACKOFF_SEC = 60.0
_HEALTH_POLL_SEC = 1.0

_STATIC_DIR = Path(__file__).resolve().parent / "static"


class StateRequest(BaseModel):
    power: bool
    r: int = Field(..., ge=0, le=255)
    g: int = Field(..., ge=0, le=255)
    b: int = Field(..., ge=0, le=255)
    brightness: int = Field(..., ge=0, le=100)


async def _maintain_connection(shutdown: asyncio.Event) -> None:
    global _lamp
    backoff = _INITIAL_BACKOFF_SEC
    while not shutdown.is_set():
        try:
            client = LampClient()
            async with client:
                _lamp = client
                LOGGER.info("lamp connected")
                backoff = _INITIAL_BACKOFF_SEC
                while not shutdown.is_set() and client.is_connected:
                    await asyncio.sleep(_HEALTH_POLL_SEC)
                if not shutdown.is_set():
                    LOGGER.warning("lamp disconnected")
        except LampNotFoundError as e:
            LOGGER.warning("scan failed: %s", e)
        except Exception:
            LOGGER.exception("connection error")
        finally:
            _lamp = None

        if shutdown.is_set():
            return

        LOGGER.info("retrying in %.1fs ...", backoff)
        try:
            await asyncio.wait_for(shutdown.wait(), timeout=backoff)
            return
        except asyncio.TimeoutError:
            pass
        backoff = min(backoff * 2, _MAX_BACKOFF_SEC)


@asynccontextmanager
async def lifespan(app: FastAPI):
    shutdown = asyncio.Event()
    task = asyncio.create_task(_maintain_connection(shutdown))
    LOGGER.info("ready: http://%s:%s (lamp connection in background)", _host(), _port())
    try:
        yield
    finally:
        shutdown.set()
        await task
        LOGGER.info("shutdown complete")


app = FastAPI(lifespan=lifespan, title="kc_smart_lamp", version="0.2.0")

# Allow browser-based clients (web UIs, voice triggers, automation pages) to call
# the API from any origin. The service binds 127.0.0.1 by default so the attack
# surface stays local; CORS only controls which web origins the browser will
# deliver responses to.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


async def _apply(state: LampState) -> dict:
    if _lamp is None:
        raise HTTPException(status_code=503, detail="lamp not connected")
    async with _lamp_lock:
        await _lamp.set_state(state)
    return {
        "ok": True,
        "state": {
            "power": state.power,
            "r": state.r,
            "g": state.g,
            "b": state.b,
            "brightness": state.brightness,
        },
    }


@app.post("/api/set_state")
async def set_state(req: StateRequest) -> dict:
    return await _apply(LampState(
        power=req.power, r=req.r, g=req.g, b=req.b, brightness=req.brightness,
    ))


@app.post("/api/lamp/on")
async def lamp_on() -> dict:
    return await _apply(LampState(power=True, r=255, g=255, b=255, brightness=100))


@app.post("/api/lamp/off")
async def lamp_off() -> dict:
    return await _apply(LampState(power=False, r=0, g=0, b=0, brightness=0))


# Mount static last so /api/* takes precedence over file paths.
app.mount("/", StaticFiles(directory=str(_STATIC_DIR), html=True), name="static")


def _host() -> str:
    return os.environ.get("LAMP_HOST", "127.0.0.1")


def _port() -> int:
    return int(os.environ.get("LAMP_PORT", "8080"))


def _open_browser_when_ready(url: str, delay_sec: float = 1.0) -> None:
    def _open() -> None:
        import time
        time.sleep(delay_sec)
        webbrowser.open(url)
    threading.Thread(target=_open, daemon=True).start()


def main() -> None:
    """Entry point for `smart-lamp-web`."""
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    host, port = _host(), _port()
    if os.environ.get("LAMP_NO_BROWSER", "") != "1":
        _open_browser_when_ready(f"http://{host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="info")
