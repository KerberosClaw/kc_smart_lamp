"""FastAPI web server: `smart-lamp-web` console script.

Serves a color-picker UI on http://localhost:8080 by default; the
single POST endpoint forwards user input to the lamp via `LampClient`.
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
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

from .ble import LampClient, LampNotFoundError, LampState

LOGGER = logging.getLogger(__name__)

# Module-level connected client + lock to serialize BLE writes across requests.
_lamp: LampClient | None = None
_lamp_lock = asyncio.Lock()

_STATIC_DIR = Path(__file__).resolve().parent / "static"


class StateRequest(BaseModel):
    power: bool
    r: int = Field(..., ge=0, le=255)
    g: int = Field(..., ge=0, le=255)
    b: int = Field(..., ge=0, le=255)
    brightness: int = Field(..., ge=0, le=100)


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _lamp
    LOGGER.info("connecting to lamp ...")
    try:
        async with LampClient() as lamp:
            _lamp = lamp
            LOGGER.info("ready: http://%s:%s", _host(), _port())
            yield
    except LampNotFoundError as e:
        LOGGER.error("startup failed: %s", e)
        raise
    finally:
        _lamp = None
        LOGGER.info("disconnected")


app = FastAPI(lifespan=lifespan, title="kc_smart_lamp", version="0.1.0")


@app.post("/api/set_state")
async def set_state(req: StateRequest) -> dict:
    if _lamp is None:
        raise HTTPException(status_code=503, detail="lamp not connected")
    state = LampState(
        power=req.power,
        r=req.r, g=req.g, b=req.b,
        brightness=req.brightness,
    )
    async with _lamp_lock:
        await _lamp.set_state(state)
    return {"ok": True, "state": req.model_dump()}


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
