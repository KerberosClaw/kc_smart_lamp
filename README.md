# Smart Lamp — A BLE Desk Lamp with No App, No Cloud, No Vendor Lock

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform: ESP32-S3](https://img.shields.io/badge/Platform-ESP32--S3-blue.svg)](https://www.espressif.com/en/products/socs/esp32-s3)
[![Protocol: BLE GATT](https://img.shields.io/badge/Protocol-BLE%20GATT-purple.svg)](https://www.bluetooth.com/specifications/gatt/)
[![Status: WIP](https://img.shields.io/badge/Status-WIP-orange.svg)](#)

[正體中文](README_zh.md)

A self-built USB-powered desk lamp controlled directly over Bluetooth Low Energy. No cloud account, no proprietary mobile app, no firmware update breaking your setup. The GATT service is documented in this repo, the firmware is open source, and the controller is just a Python script.

This project exists because every off-the-shelf BLE LED on the market today either (a) requires a vendor app, (b) hides its protocol behind reverse-engineering work, or (c) is WiFi-first. None of them satisfied "USB-powered + open BLE protocol + no app" all at once. So I'm building one.

## Architecture

```
+----------------+       BLE GATT          +-----------------+
| Host (Mac/PC)  | <---- write/notify ---> | ESP32-S3        |
| Python `bleak` |                         | NimBLE-Arduino  |
+----------------+                         | + FastLED       |
                                           +--------+--------+
                                                    |
                                                    | data
                                                    v
                                            +---------------+
                                            | WS2812B LEDs  |
                                            +---------------+
```

- **Host**: any machine with BLE — script writes to GATT characteristics
- **Device**: ESP32-S3-WROOM-1 N16R8 dev board running custom firmware
- **LEDs**: WS2812B addressable RGB strip (5V, USB-powered)
- **Enclosure**: 3D-printed shell (modeled in OpenSCAD), Bambu A1 ready

## Quick Start

> Hardware purchase, firmware flash, and pairing instructions will land here as the project progresses. This README will be updated alongside each milestone.

For now, see:
- [docs/nanopi_research.md](docs/nanopi_research.md) — NanoPi alternative path investigation (rejected, kept as reference)
- The GATT spec, firmware source, host client, and enclosure CAD will follow.

## Project Structure

```
kc_smart_lamp/
├── firmware/                 # ESP32 firmware (PlatformIO project)
├── host/                     # Python BLE client (bleak)
├── hardware/                 # 3D-printed enclosure (OpenSCAD .scad) + wiring
├── docs/                     # Design docs, decisions, bring-up plan
│   ├── decisions/            # ADRs
│   ├── dev_setup.md          # Dev environment + bring-up milestones
│   ├── procurement_guide.md  # Shopping script for hardware
│   └── nanopi_research.md    # Alternative platform investigation
├── README.md                 # This file
├── README_zh.md              # 正體中文版
├── CLAUDE.md                 # Repo conventions for Claude Code
├── LICENSE                   # MIT
├── .gitignore
└── .gitattributes
```

Three deliverable lines run in parallel: **firmware** (C++ on ESP32), **host** (Python `bleak` client), **hardware** (OpenSCAD enclosure + BOM). Each lives at its own top-level directory; `docs/` documents decisions and procedures across all three.

## Security Notice

- This project does **not** use any cloud service, vendor API, or third-party authentication.
- All communication is local BLE between host and device.
- BLE pairing uses standard Just Works / Numeric Comparison; bonded keys (LTK) are stored on-device after first pairing.
- No telemetry, no usage reporting, no remote update.
- If you discover a security issue with the firmware or host client, please open a GitHub issue.

## License

MIT — see [LICENSE](LICENSE).

## Status

Work in progress. Hardware procurement and firmware bring-up underway. Star or watch the repo to follow milestones.
