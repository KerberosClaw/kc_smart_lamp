"""Unit tests for LampState wire format — no hardware needed."""

import pytest

from lamp_client.ble import LampState


def test_to_bytes_on():
    s = LampState(power=True, r=255, g=0, b=0, brightness=50)
    assert s.to_bytes() == bytes([1, 255, 0, 0, 50])


def test_to_bytes_off():
    s = LampState(power=False, r=255, g=255, b=255, brightness=100)
    assert s.to_bytes() == bytes([0, 255, 255, 255, 100])


def test_brightness_clamped_high():
    s = LampState(power=True, r=0, g=0, b=0, brightness=150)
    assert s.to_bytes()[4] == 100


def test_brightness_clamped_low():
    s = LampState(power=True, r=0, g=0, b=0, brightness=-5)
    assert s.to_bytes()[4] == 0


def test_from_bytes():
    s = LampState.from_bytes(bytes([1, 100, 200, 50, 80]))
    assert s.power is True
    assert s.r == 100
    assert s.g == 200
    assert s.b == 50
    assert s.brightness == 80


@pytest.mark.parametrize("bad_len", [0, 1, 4, 6, 10])
def test_from_bytes_wrong_length(bad_len):
    with pytest.raises(ValueError):
        LampState.from_bytes(bytes([0] * bad_len))


def test_round_trip():
    s = LampState(power=True, r=128, g=64, b=32, brightness=75)
    assert LampState.from_bytes(s.to_bytes()) == s


def test_round_trip_off_preserves_color():
    """Off state still serializes the RGB values — firmware preserves them."""
    s = LampState(power=False, r=200, g=100, b=50, brightness=80)
    assert LampState.from_bytes(s.to_bytes()) == s
