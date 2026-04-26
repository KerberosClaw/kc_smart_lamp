"""Unit tests for color parsing — no hardware needed."""

import pytest

from lamp_client.color import parse_hex, parse_named, parse_rgb_args


def test_parse_hex_long():
    assert parse_hex("ff0000") == (255, 0, 0)
    assert parse_hex("#FF0000") == (255, 0, 0)
    assert parse_hex("00ff00") == (0, 255, 0)
    assert parse_hex("#0000FF") == (0, 0, 255)


def test_parse_hex_short():
    assert parse_hex("f00") == (255, 0, 0)
    assert parse_hex("#0f0") == (0, 255, 0)
    assert parse_hex("00F") == (0, 0, 255)


@pytest.mark.parametrize("bad", ["", "g00", "#12345", "1234567", "not_hex"])
def test_parse_hex_invalid(bad):
    with pytest.raises(ValueError):
        parse_hex(bad)


def test_parse_named_lowercase():
    assert parse_named("red") == (255, 0, 0)


def test_parse_named_case_insensitive():
    assert parse_named("RED") == (255, 0, 0)
    assert parse_named("Red") == (255, 0, 0)


def test_parse_named_invalid():
    with pytest.raises(ValueError):
        parse_named("not_a_color")


def test_parse_rgb_args_valid():
    assert parse_rgb_args([255, 0, 0]) == (255, 0, 0)
    assert parse_rgb_args((128, 128, 128)) == (128, 128, 128)


@pytest.mark.parametrize("bad", [[256, 0, 0], [-1, 0, 0], [0, 999, 0]])
def test_parse_rgb_args_out_of_range(bad):
    with pytest.raises(ValueError):
        parse_rgb_args(bad)


@pytest.mark.parametrize("bad", [[255, 0], [255, 0, 0, 0], []])
def test_parse_rgb_args_wrong_count(bad):
    with pytest.raises(ValueError):
        parse_rgb_args(bad)
