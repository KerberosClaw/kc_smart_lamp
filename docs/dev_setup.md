# Dev Setup & Bring-up Plan

> **English summary:** MacBook Pro (macOS, Apple Silicon) development setup using PlatformIO + VSCode for ESP32-S3-WROOM-1 N16R8. Hardware procured 2026-04-26 from JinHua Electronics (光華商場); WS2812B 8-LED ring pending Shopee shipment. Bring-up plan in 6 milestones: hardware power-on → BLE advertise → GATT service → on-board LED driver → external Ring driver → end-to-end host BLE write. The dev board's on-board WS2812 RGB LED lets us validate the full BLE → FastLED → LED chain before the external Ring arrives.

---

## Hardware

### Procured (2026-04-26)

| 品項 | 規格 | 數量 | 來源 |
|---|---|---|---|
| ESP32-S3-WROOM-1 N16R8 開發板 | 焊好版 PCB 天線、Native USB-C | 1 | 金華電子（光華商場） |
| 杜邦線 | 公對公 + 母對公 | 各 1 包 | 金華電子 |
| USB-C 線 | 資料 + 充電 | 1 | 既有 / 順手帶 |

**Why ESP32-S3（de facto，不是經過 ADR 的決定）**：原 `procurement_guide.md` 寫的目標是 ESP32-C3 SuperMini，採購當下材料行剛好有「焊好排針 + Native USB-C」的 S3-WROOM-1 N16R8 在貨。事後檢視這個替換 net positive — S3 比 C3 多了 PSRAM 8MB、雙核 + LP core、native USB Serial/JTAG，BLE 5.0 / FastLED / NimBLE-Arduino 全部向下相容，沒犧牲任何原本規劃的功能。**沒寫成 ADR 是因為它不是 deliberate decision，而是現場現貨決定的事實**；這段筆記就是它的歷史 record。

### Pending (蝦皮網購)

| 品項 | 規格 | 關鍵字 |
|---|---|---|
| WS2812B 8 LED Ring | **預焊線**版本（PCB pad 不要） | `WS2812B 8 LED Ring 預焊線` / `Neopixel Ring 8 焊接好` |
| USB-A 公頭 → 杜邦線 | 取 5V 給 LED 獨立供電 | `USB 取電 杜邦線` |
| 1000μF 電解電容 + 470Ω 電阻 | WS2812 防電源浪湧（POC 可省） | `WS2812 防浪湧 套件` |

到貨估 2-3 天。

### Factory Firmware Backup

板子出廠帶 ESP-IDF `example` 工廠測試 firmware（USB CDC 每 1.5 秒印 log + 板載 RGB LED 跑彩色循環）。**燒自己的 firmware 前已完整備份起來**，留作後悔藥。

| 項目 | 值 |
|---|---|
| 檔案 | `factory_dumps/factory_firmware_2026-04-26.bin` |
| 大小 | 1,114,112 bytes (1.06 MB) |
| 涵蓋範圍 | 0x0 → 0x110000（bootloader + partition table + nvs + phy_init + factory app） |
| SHA256 | `4dd0476f2da2284928220d214392ff174a8482a633b01f0fd4c99cc23c019481` |
| Partition layout | nvs @ 0x9000 (24KB) / phy_init @ 0xF000 (4KB) / factory app @ 0x10000 (1MB) |

> 備份檔案在 `.gitignore` 內（`factory_dumps/` + `*.bin`），**不會推到 GitHub**，純本地保留。

**還原指令**（萬一搞壞 / 想回到出廠狀態）：

```bash
# 1. 板子推進 download mode（按住 BOOT，按 RST，放 RST，放 BOOT；LED 停閃）
# 2. 確認裝置路徑
ls /dev/cu.usbmodem*  # 應該看到 /dev/cu.usbmodem2101（USB-Serial/JTAG endpoint）
# 3. 寫回
esptool --chip esp32s3 --port /dev/cu.usbmodem2101 \
        --before no-reset --after hard-reset \
        write-flash 0 factory_dumps/factory_firmware_2026-04-26.bin
# 4. 按 RST 確認回 firmware mode（usbmodem1234561 出現 + LED 開始彩色循環）
```

### Board-specific quirks（踩坑筆記）

這顆 S3-WROOM-1 N16R8 仿板在 macOS 上的特性，**燒錄 / debug 時會反覆遇到**：

- **兩個 USB endpoint，路徑會切換**：
  - `/dev/cu.usbmodem1234561` = USB-OTG（firmware 自做的 CDC，跑 firmware 時的 log/console）
  - `/dev/cu.usbmodem2101` = USB-Serial/JTAG（ROM bootloader + esptool 燒錄通道）
  - **裝置路徑變了 ≠ 錯誤**，是 mode 切換的正常副作用
- **Auto-reset 進 download mode 不可靠**（ESP32-S3 native USB 的 DTR/RTS 模擬問題）→ 燒錄前**手動序列**：
  1. 按住 **BOOT** 鈕
  2. 按一下 **RST**（BOOT 還按著）
  3. 放開 **RST**（BOOT 還按著）
  4. 放開 **BOOT**
  → 板載 LED 停閃 = 已進 download mode
- **`esptool --baud 921600` 不穩**：~7% 處會 `Serial data stream stopped`。**改 `--baud 115200`**（雖只 11 KB/s 但穩）。實務上備份只需 0x0-0x110000 = 1.5 分鐘
- **`--after hard-reset` 常常不會真的踢回 firmware mode**：判斷方法 — `ls /dev/cu.usbmodem*` 看到 `usbmodem1234561` 才是真的回去了，沒看到就**手動按一下 RST**
- **板載 RGB LED 是 WS2812 單顆**（同協定，跟 Ring 一樣可用 FastLED 驅動），可在 Ring 到貨前先把整條 BLE→LED chain 驗起來；GPIO 預設先試 **GPIO 48**（官方 ESP32-S3-DevKitC-1 接法），不亮再試 38 / 47

---

## Development Environment

### Target machine

MacBook Pro (macOS, Apple Silicon)。

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

### M1: Hardware power-on（不接 LED 不裝環境也能做） ✅ Validated 2026-04-26

- USB-C 線接 ESP32 ↔ Mac mini（**直插主機，不要過 hub**）
- **觀察板上 LED**：紅色電源 LED 應常亮；boot 期間可能有藍/紫 LED 閃
- **macOS 認到 device**：terminal 跑 `ls /dev/cu.* | grep usbmodem`，應有 `/dev/cu.usbmodem<id>`（Native USB，**不需要 driver**）
- ⚠️ 沒燈 / 沒 device → 換 USB 線（爛線會「能充電不能傳資料」）

**Exit criteria**：`ls /dev/cu.usbmodem*` 看到 device。

### M2: BLE advertise demo ✅ Validated 2026-04-26

**驗證紀錄**：燒錄完手動按 RST 後，板載 LED 跑 R/G/B boot self-test → BLE 開始 advertise。`bleak.BleakScanner.find_device_by_name('kc_smart_lamp')` 在 5 秒內找到 device。iPhone nRF Connect 同樣掃得到。

- PlatformIO 建 `firmware/` project（Board: ESP32-S3-DevKitC-1，Framework: Arduino）
- 燒一個 minimal NimBLE-Arduino BLE advertiser（device name `kc_smart_lamp`）
- 手機開 nRF Connect → Scan → **看到 `kc_smart_lamp`** = BLE 通

**Exit criteria**：手機 BLE scanner 掃到自定 device name。

### M3: GATT service + write characteristic ✅ Validated 2026-04-26

**驗證紀錄**：三個 client 並行驗證寫入 `LAMP_STATE` 都 work — (1) `smart-lamp --hex FF0000 --brightness 50 --on` CLI、(2) FastAPI Web UI 色盤 + slider + Apply、(3) iPhone nRF Connect hex write `01ff000032`。三者寫進去 LED 都正確顯示對應顏色 / 亮度。

GATT spec 已正式化在 [docs/gatt_spec.md](gatt_spec.md) — 單一 service + 單一 5-byte `LAMP_STATE` characteristic（power/RGB/brightness 原子寫入）。

- firmware: NimBLE-Arduino 建 service + characteristic（已寫在 `firmware/src/main.cpp`）
- write callback 把 5 bytes 解開印 Serial、套到 FastLED
- host: `lamp_client/ble.py` 提供 `LampClient` async context manager（`async with` connect → `set_state()` 寫 → 自動斷）
- CLI 驗證：`smart-lamp --hex FF0000 --brightness 50 --on`
- Serial Monitor 看到 `[ble] state: power=1 rgb=(255,0,0) brightness=50%`

**Exit criteria**：CLI 寫紅色 → Serial Monitor 印對應 5 bytes 解析值。

**🔖 Future TODO（v1.1，已 memo）**：CLI 跟 Web 都要加 **`status` 讀取功能**，理由是 user 可能想「保留顏色，只調亮度／開關」。
- Lib 層 `LampClient.get_state()` **已實作**（v1 從第一天就完整）
- CLI / Web 還沒暴露這個指令；要時再 wire 約 10 行 code
- Use cases + 對應改動見 [gatt_spec.md → "Future: client-side status command"](gatt_spec.md)

### M4a: 板載 LED 驗證 FastLED + GATT chain（不等 Ring 到貨也能做） ✅ Validated 2026-04-26

**驗證紀錄**：板載 WS2812 LED 在 GPIO 48（platformio.ini `LAMP_LED_PIN=48`），boot self-test 紅 → 綠 → 藍 → 熄滅順利執行；BLE write 後 LED 色 / 亮度即時反應。**這顆 S3-WROOM-1 N16R8 仿板的 on-board LED 確實在 GPIO 48**，跟官方 ESP32-S3-DevKitC-1 一致，沒踩到 38 / 47 變體。

板子有內建一顆 WS2812 RGB LED（出廠 firmware 跑彩色循環的就是它），協定跟外接 Ring 完全一樣 — 拿來先把 BLE → FastLED → WS2812 整條鏈路驗起來，**Ring 到貨前 2-3 天可以先把 firmware 寫完**。

- firmware 加 `FastLED` lib（PlatformIO `lib_deps`）
- `NUM_LEDS = 1`、data pin 預設 **GPIO 48**（官方 ESP32-S3-DevKitC-1 接法）→ 不亮再依序試 GPIO 38、47
- 把 M3 的 GATT write callback 改成 `leds[0] = CRGB(R, G, B); FastLED.show();`
- 補一段 boot self-test：開機 1 秒紅、1 秒綠、1 秒藍 → 證明 GPIO + FastLED 對

**Exit criteria**：
1. 燒進去後板載 LED 跑紅綠藍 self-test（不再是出廠的隨機色循環）
2. Mac Python script 寫 `(255, 0, 0)` → 板載 LED 變紅
3. 寫 `(0, 0, 0)` → 板載 LED 熄滅

### M4b: 外接 8-LED Ring（等 Ring 到貨後做）

幾乎只是改常數 + 接線。**firmware 邏輯 100% 沿用 M4a**：

- 接線：
  - **5V** → ESP32 5V pin（USB 直給；8 顆滿亮 ~480mA，USB 5V 足夠）
  - **GND** → ESP32 GND（共地必須，否則 LED 抖 / 不亮）
  - **DIN** → ESP32 GPIO（建議 GPIO 18，或任一空閒非 strapping pin）
- firmware 改兩行：
  - `NUM_LEDS = 8`
  - `#define LED_PIN 18`（或實際接的腳）
- 重新燒，BLE 寫紅色 → 8 顆全紅

**邊界注意**：ESP32-S3 是 3.3V logic，WS2812B spec 標 5V data。短距離 + 低 LED 數通常 work；若閃爍 / 顏色不對，加 level shifter（74AHCT125 之類）。

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

- [GATT spec](gatt_spec.md) — service + characteristic 正式定義
- [ESP32-S3-WROOM-1 datasheet (Espressif)](https://www.espressif.com/sites/default/files/documentation/esp32-s3-wroom-1_wroom-1u_datasheet_en.pdf)
- [NimBLE-Arduino GitHub](https://github.com/h2zero/NimBLE-Arduino)
- [FastLED](https://github.com/FastLED/FastLED)
- [bleak (Python BLE)](https://github.com/hbldh/bleak)
- [PlatformIO ESP32-S3-DevKitC-1 board](https://docs.platformio.org/en/latest/boards/espressif32/esp32-s3-devkitc-1.html)
