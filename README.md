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

### Host — CLI + Web (cross-platform)

Tested on macOS / Linux / Windows. Requires Python 3.12+.

```bash
pipx install ./host

smart-lamp-web                                       # Web UI on http://localhost:8080
smart-lamp --hex FF0000 --brightness 50 --on        # CLI: red at 50%
smart-lamp --color blue --brightness 80             # CLI: named color
smart-lamp --off                                     # CLI: turn off
```

If you don't have `pipx`: `python3 -m pip install --user pipx && pipx ensurepath`.

### Firmware — one-time flash (requires the dev board)

```bash
pipx install platformio
cd firmware

# Put board in download mode: hold BOOT, press RST, release RST, release BOOT
pio run -t upload          # build + flash
pio device monitor         # tail boot log (115200 baud)
```

After flashing, the lamp advertises as `kc_smart_lamp` over BLE and waits for writes.

See [docs/dev_setup.md](docs/dev_setup.md) for download-mode quirks, factory firmware backup, and bring-up milestones; [docs/gatt_spec.md](docs/gatt_spec.md) for the wire-level service / characteristic definition.

### Platform-specific notes

- **Windows**: First run prompts for Bluetooth permission — click Allow. ESP32-S3 USB drivers auto-install on Windows 10/11.
- **Linux**: `bluez` must be running. Some distributions need `sudo setcap cap_net_raw+eip $(readlink -f $(which python3))` for unprivileged BLE scanning.
- **macOS**: Native via CoreBluetooth, no extra setup.

### Reference

- [docs/gatt_spec.md](docs/gatt_spec.md) — GATT service / characteristic spec
- [docs/dev_setup.md](docs/dev_setup.md) — dev environment + 6-milestone bring-up plan
- [docs/procurement_guide.md](docs/procurement_guide.md) — hardware shopping script
- [docs/nanopi_research.md](docs/nanopi_research.md) — alternative platform investigation (rejected, kept as reference)
- [docs/decisions/](docs/decisions/) — architectural decision records (ADRs)

## Project Structure

```
kc_smart_lamp/
├── firmware/                 # ESP32 firmware (PlatformIO project)
├── host/                     # Python BLE client (bleak) — CLI + Web UI
├── ios/                      # iOS app (SwiftUI + CoreBluetooth) — reference impl, awaiting Xcode wrap
├── hardware/                 # 3D-printed enclosure (OpenSCAD .scad) + wiring
├── docs/                     # Design docs, decisions, bring-up plan
│   ├── decisions/            # ADRs
│   ├── gatt_spec.md          # BLE GATT service / characteristic spec
│   ├── app_design_brief.md   # iOS app design direction
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

Four deliverable lines run in parallel: **firmware** (C++ on ESP32), **host** (Python `bleak` client — CLI + Web), **ios** (SwiftUI + CoreBluetooth app), **hardware** (OpenSCAD enclosure + BOM). Each lives at its own top-level directory; `docs/` documents decisions and procedures across all four.

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
