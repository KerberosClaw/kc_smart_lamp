"""Color parsing helpers — pure functions, no I/O."""

from __future__ import annotations

import re

RGB = tuple[int, int, int]

NAMED_COLORS: dict[str, RGB] = {
    "red":     (255, 0, 0),
    "green":   (0, 255, 0),
    "blue":    (0, 0, 255),
    "white":   (255, 255, 255),
    "yellow":  (255, 255, 0),
    "cyan":    (0, 255, 255),
    "magenta": (255, 0, 255),
    "orange":  (255, 165, 0),
    "purple":  (128, 0, 128),
    "warm":    (255, 180, 100),
    "cool":    (200, 220, 255),
}

_HEX_PATTERN = re.compile(r"^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$")


def parse_hex(s: str) -> RGB:
    """Parse hex color: 'FF0000', '#FF0000', 'F00', '#F00'."""
    m = _HEX_PATTERN.match(s)
    if not m:
        raise ValueError(f"invalid hex color: {s!r}")
    h = m.group(1)
    if len(h) == 3:
        h = h[0] * 2 + h[1] * 2 + h[2] * 2
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def parse_named(name: str) -> RGB:
    """Look up a named color (case-insensitive)."""
    key = name.lower()
    if key not in NAMED_COLORS:
        raise ValueError(f"unknown color name: {name!r}")
    return NAMED_COLORS[key]


def parse_rgb_args(rgb: list[int] | tuple[int, ...]) -> RGB:
    """Validate three ints in 0-255."""
    if len(rgb) != 3:
        raise ValueError(f"expected 3 RGB values, got {len(rgb)}")
    for v in rgb:
        if not 0 <= v <= 255:
            raise ValueError(f"RGB value out of range 0-255: {v}")
    return (rgb[0], rgb[1], rgb[2])
