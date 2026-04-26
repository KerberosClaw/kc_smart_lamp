"""CLI entry point: `smart-lamp` console script."""

from __future__ import annotations

import argparse
import asyncio
import logging
import sys

from .ble import LampClient, LampNotFoundError, LampState
from .color import parse_hex, parse_named, parse_rgb_args


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="smart-lamp",
        description="Control kc_smart_lamp over BLE.",
    )

    color_group = p.add_mutually_exclusive_group()
    color_group.add_argument("--hex", dest="hex", metavar="HEX",
                             help="Color as hex: FF0000 / #FF0000 / F00")
    color_group.add_argument("--rgb", nargs=3, type=int, metavar=("R", "G", "B"),
                             help="Color as three ints 0-255")
    color_group.add_argument("--color", metavar="NAME",
                             help="Named color: red / green / blue / white / ...")

    p.add_argument("--brightness", type=int, default=50, metavar="0-100",
                   help="Brightness percent (default: 50)")

    power_group = p.add_mutually_exclusive_group()
    power_group.add_argument("--on", dest="on", action="store_true",
                             help="Turn lamp on (default if any color given)")
    power_group.add_argument("--off", dest="off", action="store_true",
                             help="Turn lamp off (color/brightness ignored)")

    p.add_argument("--scan-timeout", type=float, default=5.0,
                   help="BLE scan timeout in seconds (default: 5.0)")
    p.add_argument("-v", "--verbose", action="store_true")
    return p


def resolve_state(args: argparse.Namespace) -> LampState:
    if args.off:
        return LampState(power=False, r=0, g=0, b=0, brightness=0)

    if args.hex is not None:
        rgb = parse_hex(args.hex)
    elif args.rgb is not None:
        rgb = parse_rgb_args(args.rgb)
    elif args.color is not None:
        rgb = parse_named(args.color)
    else:
        raise SystemExit("error: specify --hex / --rgb / --color, or --off")

    brightness = max(0, min(100, args.brightness))
    return LampState(power=True, r=rgb[0], g=rgb[1], b=rgb[2], brightness=brightness)


async def run(args: argparse.Namespace) -> int:
    state = resolve_state(args)
    print(f"applying: {state}")
    async with LampClient(timeout=args.scan_timeout) as lamp:
        await lamp.set_state(state)
    print("done.")
    return 0


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(message)s",
    )
    try:
        rc = asyncio.run(run(args))
    except LampNotFoundError as e:
        print(f"error: {e}", file=sys.stderr)
        rc = 2
    except (RuntimeError, ValueError) as e:
        print(f"error: {e}", file=sys.stderr)
        rc = 1
    sys.exit(rc)
