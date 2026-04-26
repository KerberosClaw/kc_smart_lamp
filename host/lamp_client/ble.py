"""BLE client for kc_smart_lamp.

Backed by `bleak`, which uses CoreBluetooth (macOS), BlueZ (Linux), and
WinRT (Windows 10+). The wire format is documented in docs/gatt_spec.md.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

from bleak import BleakClient, BleakScanner

LOGGER = logging.getLogger(__name__)

DEVICE_NAME = "kc_smart_lamp"
SERVICE_UUID = "2f421b7d-41dd-4de6-a19a-1194b4d04361"
LAMP_STATE_UUID = "2f421b7d-41dd-4de6-a19a-a2a6dae023f9"


class LampNotFoundError(RuntimeError):
    """Raised when no advertising lamp is discoverable."""


@dataclass
class LampState:
    power: bool
    r: int
    g: int
    b: int
    brightness: int  # 0-100

    def to_bytes(self) -> bytes:
        return bytes([
            1 if self.power else 0,
            self.r & 0xFF,
            self.g & 0xFF,
            self.b & 0xFF,
            max(0, min(100, self.brightness)),
        ])

    @classmethod
    def from_bytes(cls, data: bytes) -> "LampState":
        if len(data) != 5:
            raise ValueError(f"expected 5 bytes, got {len(data)}")
        return cls(
            power=data[0] != 0,
            r=data[1],
            g=data[2],
            b=data[3],
            brightness=data[4],
        )


class LampClient:
    """Async BLE session for kc_smart_lamp.

    Use as an async context manager:

        async with LampClient() as lamp:
            await lamp.set_state(LampState(True, 255, 0, 0, 50))
    """

    def __init__(self, name: str = DEVICE_NAME, timeout: float = 5.0):
        self._name = name
        self._timeout = timeout
        self._client: BleakClient | None = None

    async def __aenter__(self) -> "LampClient":
        LOGGER.info("scanning for %r (timeout=%.1fs) ...", self._name, self._timeout)
        device = await BleakScanner.find_device_by_name(self._name, timeout=self._timeout)
        if device is None:
            raise LampNotFoundError(
                f"no BLE device named {self._name!r} found within {self._timeout}s"
            )
        LOGGER.info("found %s [%s]", device.name, device.address)
        self._client = BleakClient(device)
        await self._client.connect()
        LOGGER.info("connected")
        return self

    async def __aexit__(self, *exc) -> None:
        if self._client is not None:
            try:
                await self._client.disconnect()
            finally:
                self._client = None

    def _require(self) -> BleakClient:
        if self._client is None or not self._client.is_connected:
            raise RuntimeError("not connected — wrap calls in 'async with'")
        return self._client

    async def set_state(self, state: LampState) -> None:
        payload = state.to_bytes()
        LOGGER.info("write LAMP_STATE: %s -> %s", state, payload.hex())
        await self._require().write_gatt_char(LAMP_STATE_UUID, payload, response=True)

    async def get_state(self) -> LampState:
        """Read current state. Reserved for future client status feature."""
        data = await self._require().read_gatt_char(LAMP_STATE_UUID)
        return LampState.from_bytes(bytes(data))
