# 智慧檯燈 — 沒 App、沒雲端、沒廠商鎖死的 BLE 桌燈

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform: ESP32-S3](https://img.shields.io/badge/Platform-ESP32--S3-blue.svg)](https://www.espressif.com/en/products/socs/esp32-s3)
[![Protocol: BLE GATT](https://img.shields.io/badge/Protocol-BLE%20GATT-purple.svg)](https://www.bluetooth.com/specifications/gatt/)
[![Status: WIP](https://img.shields.io/badge/Status-WIP-orange.svg)](#)

[English](README.md)

一盞自製、USB 供電、直接走 Bluetooth Low Energy 控制的桌燈。不用雲端帳號、不裝廠商 App、不會被 firmware 更新搞壞。GATT service 規格寫在這個 repo 裡、韌體開源、控制端就是一支 Python script。

這個專案存在的原因是：市售 BLE 智能燈泡 100% 落入下面三類之一 — (a) 必須裝廠商 App、(b) 協議只能靠社群逆向、(c) 是 WiFi 優先而非 BLE。沒有任何一款同時滿足「USB 供電 + BLE 協議公開 + 不綁 App」。沒有就自己做。

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

> 採購清單、韌體燒錄、配對流程會隨專案進展補上 README。

目前可看：
- [docs/nanopi_research.md](docs/nanopi_research.md) — NanoPi 替代路線調研（已棄用，保留作為對照）
- GATT 規格、韌體原始碼、host client、外殼 CAD 後續陸續加入

## 專案結構

```
kc_smart_lamp/
├── firmware/                 # ESP32 韌體（PlatformIO project）
├── host/                     # Python BLE client（bleak）
├── hardware/                 # 3D 列印外殼（OpenSCAD .scad）+ 配線
├── docs/                     # 設計文件、決策、bring-up plan
│   ├── decisions/            # ADRs
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

三條 deliverable line 並行：**firmware**（ESP32 上的 C++）、**host**（Python `bleak` client）、**hardware**（OpenSCAD 外殼 + BOM），各自一個 top-level 目錄；`docs/` 跨三條線記錄決策與流程。

## 安全聲明

- 本專案**不使用**任何雲端服務、廠商 API、第三方認證
- 所有通訊都是 host 跟 device 之間的本地 BLE
- BLE 配對走標準 Just Works / Numeric Comparison；首次配對後保留長期金鑰（LTK）於裝置
- 沒有遙測、沒有用量回報、沒有遠端更新
- 如發現韌體或 client 安全問題，請開 GitHub issue

## License

MIT — 見 [LICENSE](LICENSE)。

## Status

Work in progress。硬體採購 + 韌體 bring-up 進行中。Star / Watch repo 追蹤進度。
