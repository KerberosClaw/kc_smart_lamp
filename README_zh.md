# 智慧檯燈 — 沒 App、沒雲端、沒廠商鎖死的 BLE 桌燈

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform: ESP32-S3](https://img.shields.io/badge/Platform-ESP32--S3-blue.svg)](https://www.espressif.com/en/products/socs/esp32-s3)
[![Protocol: BLE GATT](https://img.shields.io/badge/Protocol-BLE%20GATT-purple.svg)](https://www.bluetooth.com/specifications/gatt/)
[![Status: WIP](https://img.shields.io/badge/Status-WIP-orange.svg)](#)

[English](README.md)

一盞 USB 供電、走 Bluetooth、不對外通訊的桌燈。GATT 規格寫在這個 repo 裡、韌體開源、控制端就是一支 Python script — 不用雲端帳號、不裝廠商 App、不會哪天 firmware 更新給你變磚。

起點是「我只是想要一盞燈，不要叫我裝 App」。兩週後變成 firmware + Python CLI + Web UI + iOS app，因為市售 BLE 智能燈泡 100% 落入下面三類之一：(a) 必須裝廠商 App、(b) 協議靠社群逆向、(c) 是 WiFi 優先而非 BLE。沒有任何一款同時滿足「USB 供電 + BLE 協議公開 + 不綁 App」。沒有就自己做。

## 架構

```
+----------------+       BLE GATT          +-----------------+
| Host (Mac/PC)  | <----- 讀寫 / 通知 ---> | ESP32-S3        |
| Python `bleak` |                         | NimBLE-Arduino  |
+----------------+                         | + FastLED       |
                                           +--------+--------+
                                                    |
                                                    | 數據
                                                    v
                                            +---------------+
                                            | WS2812B LEDs  |
                                            +---------------+
```

- **Host**：任何支援 BLE 的機器，script 寫 GATT 特徵值
- **Device**：ESP32-S3-WROOM-1 N16R8 開發板跑自寫韌體
- **LEDs**：WS2812B 可定址 RGB 燈條（5V，USB 供電）
- **外殼**：3D 列印（OpenSCAD 建模），拓竹 A1 直接吃

## 快速開始

### Host — CLI + Web（跨平台）

macOS / Linux / Windows 都通，需要 Python 3.12+。

```bash
pipx install ./host

smart-lamp-web                                      # Web UI 在 http://localhost:8080
smart-lamp --hex FF0000 --brightness 50 --on       # CLI：紅色 50%
smart-lamp --color blue --brightness 80            # CLI：命名色
smart-lamp --off                                    # CLI：關燈
```

沒裝 `pipx`：`python3 -m pip install --user pipx && pipx ensurepath`。

### Firmware — 一次性燒錄（需要開發板）

```bash
pipx install platformio
cd firmware

# 板子推進 download mode：按住 BOOT、按 RST、放 RST、放 BOOT
pio run -t upload          # 編譯 + 燒錄
pio device monitor         # 看 boot log（115200 baud）
```

燒完後 lamp 會以 `kc_smart_lamp` 廣播 BLE，等 client 寫入。

詳細燒錄踩坑（download mode 序列、出廠 firmware 備份等）看 [docs/dev_setup.md](docs/dev_setup.md)；BLE wire 規格看 [docs/gatt_spec.md](docs/gatt_spec.md)。

### 平台特殊事項

- **Windows**：第一次跑會跳 Bluetooth 權限視窗，點允許。Win10/11 自動裝 ESP32-S3 USB 驅動
- **Linux**：`bluez` 要在跑。部分發行版要 `sudo setcap cap_net_raw+eip $(readlink -f $(which python3))` 才能不用 root 掃 BLE
- **macOS**：CoreBluetooth native，零額外設定

### 參考文件

- [docs/gatt_spec.md](docs/gatt_spec.md) — BLE GATT service / characteristic 規格
- [docs/dev_setup.md](docs/dev_setup.md) — 開發環境 + 6 個 milestone bring-up plan
- [docs/procurement_guide.md](docs/procurement_guide.md) — 硬體採購照唸腳本
- [docs/nanopi_research.md](docs/nanopi_research.md) — 替代平台調研（已棄用，保留對照）
- [docs/decisions/](docs/decisions/) — 架構決策紀錄（ADR）

## 專案結構

```
kc_smart_lamp/
├── firmware/                 # ESP32 韌體（PlatformIO project）
├── host/                     # Python BLE client（bleak）— CLI + Web UI
├── ios/                      # iOS app（SwiftUI + CoreBluetooth）— SwiftUI 參考實作已 ready，待 Xcode 包專案
├── hardware/                 # 3D 列印外殼（OpenSCAD .scad）+ 配線
├── docs/                     # 設計文件、決策、bring-up plan
│   ├── decisions/            # ADRs
│   ├── gatt_spec.md          # BLE GATT service / characteristic 規格
│   ├── app_design_brief.md   # iOS app 設計方向
│   ├── dev_setup.md          # 開發環境 + bring-up milestones
│   ├── procurement_guide.md  # 採購照唸腳本
│   └── nanopi_research.md    # 替代平台調研
├── README.md                 # English
├── README_zh.md              # 本檔
├── CLAUDE.md                 # repo 給 Claude Code 用的守則
├── LICENSE                   # MIT
├── .gitignore
└── .gitattributes
```

四條 deliverable line 並行：**firmware**（ESP32 上的 C++）、**host**（Python `bleak` client — CLI + Web）、**ios**（SwiftUI + CoreBluetooth app）、**hardware**（OpenSCAD 外殼 + BOM），各自一個 top-level 目錄；`docs/` 跨四條線記錄決策與流程。

## 安全聲明

- 本專案**不使用**任何雲端服務、廠商 API、第三方認證
- 所有通訊都是 host 跟 device 之間的本地 BLE
- BLE 配對走標準 Just Works / Numeric Comparison；首次配對後保留長期金鑰（LTK）於裝置
- 沒有遙測、沒有用量回報、沒有遠端更新
- 如發現韌體或 client 安全問題，請開 GitHub issue

## License

MIT — 見 [LICENSE](LICENSE)。

## Status

Work in progress — 硬體 2026-04-26 採購完成、韌體 bring-up 進行中、`docs/decisions/` 裡已經有半打 ADR 在跟過去的決定吵架。Star / Watch 追蹤進度（順便看「結果這條路不通」的 pivot）。
