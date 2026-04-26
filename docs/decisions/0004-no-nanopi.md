# ADR 0004: 不用 NanoPi，走 ESP32 + BLE

**Status**: Accepted（platform 已選定 ESP32-S3，本 ADR 紀錄 NanoPi 為何被淘汰）
**Date**: 2026-04-26
**Replaces**: 早期 `docs/nanopi_research.md` 完整調研檔（已歸檔於 git history）

## Context

家裡有一片 FriendlyARM 初代 NanoPi（2015，Samsung S3C2451 / 64MB RAM / armel）。最初構想是把它做成「桌面 IoT 燈」— Linux SBC 跑 REST API，MBP curl 控 LED。動機純粹是「reuse 既有硬體」。

實作前花了一輪做技術調研 + 一次 Path B（UTM Linux VM 燒 SD）試燒，後來決定棄 NanoPi 改走 ESP32 + BLE GATT。本 ADR 記錄淘汰 NanoPi 的理由，作為「同樣需求兩種解法的對照組」。

## Options Considered

| 平台 | 通訊 | 優點 | 致命傷 |
|---|---|---|---|
| NanoPi (2015) + WiFi REST | HTTP API | 家裡有貨、跑得動 Python | 見下方 4 個致命傷 |
| **ESP32-S3 + BLE GATT** ⭐ | BLE peripheral | 秒開、tooling 成熟、無 OS overhead | 要新買 |

## Decision

**走 ESP32-S3 + BLE GATT**，NanoPi 棄用。

## Rationale — NanoPi 的 4 個致命傷

1. **軟體生態死亡** — armel ARMv5 EABI + Debian 8（EOL）。modern Python 套件、Docker、新版 Node.js 多數無 prebuilt。`bluez` peripheral mode 在這版本要 hack，`spidev` 雖有 armel 版但 WS2812B library 找不到 — 要自己手寫 SPI bit-bang。

2. **WS2812B 時序需 hack** — Linux GPIO sysfs 抖動爆炸不夠 800kHz ±150ns。要靠 SPI MOSI 模擬時序（每 WS2812 bit 用 4 個 SPI bit 編碼），bypass scheduler 才穩。能跑但脆弱、沒人維護。

3. **Linux boot ~30 秒不適合 lamp UX** — 桌燈期望「按一下亮」。30 秒 boot 對 daily use 是體驗殺手。常開機又跟「USB-powered 桌燈」省電/熱管理衝突。

4. **M1 MBP 不支援 USB Gadget RNDIS** — HoRNDIS 只 Intel Mac。第一次 SSH 必須繞路（PC 燒卡、或 Mac 開 UTM Linux VM 預配 WiFi 跳過 RNDIS）。Onboarding 摩擦大。

加碼一個非致命但累積的：**S3C2451 iROM boot layout 詭異**（bootloader 必須在 SD 卡末端固定 sector，無法 dd 一般 raw image），燒卡本身就是踩雷區（util-linux 2.32+ 移除 sfdisk 旗標、rootfs URL 過期 cert、image size 必須等於 SD 容量等）。

## Rationale — ESP32-S3 + BLE 的對照

- **Boot < 1 秒** — 通電到 BLE advertise，user 感覺不到延遲
- **WS2812B 一等公民** — FastLED + Arduino framework 直接驅，無 timing hack
- **Tooling 直球** — PlatformIO + VSCode，cross-compile 自動處理
- **Mac 直接連** — CoreBluetooth native，零 driver 設定
- **無 OS overhead** — 沒 distro / 沒 service / 沒 syslog 要管，韌體就是 firmware

## Consequences

### 正面

- bring-up 從「燒 SD + 設 WiFi + debug Linux + 寫 SPI bit-bang」收斂到「燒 firmware + BLE write」
- Tooling 現代且維護中（PlatformIO / NimBLE-Arduino / FastLED 都活躍）
- 跨平台 client 自動成立（任何有 BLE 的機器都能寫）

### 負面

- 多花 ESP32 dev board 採購
- BLE 範圍 ~10m vs WiFi 全屋 — 但桌燈 use case 在桌邊，不需要全屋

## Lesson Learned

「reuse 既有硬體」聽起來省錢，但若硬體所在 ecosystem 已死（armel + Debian 8），救活的時間成本遠高於買新硬體。**用對工具比省一片板子重要**。NanoPi 那片繼續當紀念品。
