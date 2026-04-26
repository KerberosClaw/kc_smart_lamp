# Dev Setup & Bring-up Plan

> **English summary:** Mac mini macOS development setup using PlatformIO + VSCode for ESP32-S3-WROOM-1 N16R8. Hardware procured 2026-04-26 from JinHua Electronics (光華商場); WS2812B 8-LED ring pending Shopee shipment. Bring-up plan in 5 milestones: hardware power-on → BLE advertise → GATT service → LED driver → end-to-end host BLE write.

---

## Hardware

### Procured (2026-04-26)

| 品項 | 規格 | 數量 | 來源 |
|---|---|---|---|
| ESP32-S3-WROOM-1 N16R8 開發板 | 焊好版 PCB 天線、Native USB-C | 1 | 金華電子（光華商場）NT$ 400 |
| 杜邦線 | 公對公 + 母對公 | 各 1 包 | 金華電子 |
| USB-C 線 | 資料 + 充電 | 1 | 既有 / 順手帶 |

### Pending (蝦皮網購)

| 品項 | 規格 | 預估 | 關鍵字 |
|---|---|---|---|
| WS2812B 8 LED Ring | **預焊線**版本（PCB pad 不要） | NT$ 50-100 | `WS2812B 8 LED Ring 預焊線` / `Neopixel Ring 8 焊接好` |
| USB-A 公頭 → 杜邦線 | 取 5V 給 LED 獨立供電 | NT$ 30 | `USB 取電 杜邦線` |
| 1000μF 電解電容 + 470Ω 電阻 | WS2812 防電源浪湧（POC 可省） | NT$ 30 | `WS2812 防浪湧 套件` |

到貨估 2-3 天。

---

## Development Environment

### Target machine

Mac mini (macOS, Apple Silicon 推測)。

### Required tools

| 工具 | 用途 | 安裝 |
|---|---|---|
| **VSCode** | Editor | 已裝 |
| **PlatformIO IDE** | ESP32 build / flash / monitor | VSCode Extensions tab 搜 `PlatformIO IDE` install |
| **nRF Connect** (手機 app) | BLE scanner / GATT explorer | App Store / Play Store 免費 |
| **Python 3.12+ + bleak** | Mac 端 BLE client | `pip install bleak`（virtualenv 建議）|

### 為什麼選 PlatformIO（不選 Arduino IDE）

- `platformio.ini` 鎖 board + framework + lib version → reproducible build
- 跟 git track 友善（lib version 寫進 ini 不用 commit lib 全套）
- VSCode 整合好，跟現有 editor 不衝突
- 未來換 board / 加 ESP32-C3 變體只改 ini

ESP-IDF 太重，POC 用不到。Arduino IDE 適合 quick demo 但 project 結構簡陋。

---

## Bring-up Milestones

### M1: Hardware power-on（不接 LED 不裝環境也能做）

- USB-C 線接 ESP32 ↔ Mac mini（**直插主機，不要過 hub**）
- **觀察板上 LED**：紅色電源 LED 應常亮；boot 期間可能有藍/紫 LED 閃
- **macOS 認到 device**：terminal 跑 `ls /dev/cu.* | grep usbmodem`，應有 `/dev/cu.usbmodem<id>`（Native USB，**不需要 driver**）
- ⚠️ 沒燈 / 沒 device → 換 USB 線（爛線會「能充電不能傳資料」）

**Exit criteria**：`ls /dev/cu.usbmodem*` 看到 device。

### M2: BLE advertise demo

- PlatformIO 建 `firmware/` project（Board: ESP32-S3-DevKitC-1，Framework: Arduino）
- 燒一個 minimal NimBLE-Arduino BLE advertiser（device name `kc_smart_lamp`）
- 手機開 nRF Connect → Scan → **看到 `kc_smart_lamp`** = BLE 通

**Exit criteria**：手機 BLE scanner 掃到自定 device name。

### M3: GATT service + write characteristic

- ESP32 firmware 加自定 GATT service（自選 UUID）
- 加一個 `write` characteristic（接 RGB byte stream，例如 3 bytes `R G B`）
- write callback 把收到的值用 Serial print 出來
- Mac 端寫 Python `bleak` script：scan → connect → write characteristic
- 在 PlatformIO Serial Monitor 看到 ESP32 收到對應值

**Exit criteria**：Mac Python script 寫 `(255, 0, 0)` → Serial Monitor 印 `R=255 G=0 B=0`。

### M4: LED 接上 + FastLED 驅動（等 LED 到貨）

- WS2812B 8-LED Ring 接線：
  - **5V** → ESP32 5V pin（USB 直給）
  - **GND** → ESP32 GND
  - **DIN** → ESP32 GPIO（建議 GPIO 18 或任一空閒 pin）
- firmware 加 FastLED lib，把 GATT write callback 改成 `leds[0..7] = CRGB(R, G, B); FastLED.show();`
- 從 Mac 寫 BLE → LED 真的變色

**Exit criteria**：Mac 寫紅色 → Ring 8 顆 LED 全紅。

### M5: End-to-end + bonding

- BLE pairing + bonding（首次配對，重開機後自動重連）
- 自定 GATT service 完整實作：
  - `LED_RGB` characteristic（write 3 bytes）
  - `BRIGHTNESS` characteristic（write 1 byte 0-255）
  - `STATE` characteristic（read，回現在狀態）
- Mac 端寫 user-friendly script（`python lamp.py red` / `python lamp.py off`）

**Exit criteria**：Mac 重開、ESP32 重開後，script 自動重連並控 LED 不用重新配對。

---

## Out of scope (POC 階段不做)

- 多裝置管理 / scene / 排程
- OTA firmware update
- WiFi 連線（純 BLE，不掛 WiFi）
- 工業級電源 / 認證模組

---

## Reference

- [ESP32-S3-WROOM-1 datasheet (Espressif)](https://www.espressif.com/sites/default/files/documentation/esp32-s3-wroom-1_wroom-1u_datasheet_en.pdf)
- [NimBLE-Arduino GitHub](https://github.com/h2zero/NimBLE-Arduino)
- [FastLED](https://github.com/FastLED/FastLED)
- [bleak (Python BLE)](https://github.com/hbldh/bleak)
- [PlatformIO ESP32-S3-DevKitC-1 board](https://docs.platformio.org/en/latest/boards/espressif32/esp32-s3-devkitc-1.html)
