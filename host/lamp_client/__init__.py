"""kc_smart_lamp BLE host library.

Cross-platform (macOS / Linux / Windows) BLE client for kc_smart_lamp.
See docs/gatt_spec.md for the wire-level GATT specification.
"""

from .ble import (
    DEVICE_NAME,
    LAMP_STATE_UUID,
    SERVICE_UUID,
    LampClient,
    LampNotFoundError,
    LampState,
)
from .color import NAMED_COLORS, parse_hex, parse_named, parse_rgb_args

__version__ = "0.2.0"

__all__ = [
    "DEVICE_NAME",
    "SERVICE_UUID",
    "LAMP_STATE_UUID",
    "LampClient",
    "LampState",
    "LampNotFoundError",
    "parse_hex",
    "parse_named",
    "parse_rgb_args",
    "NAMED_COLORS",
]
