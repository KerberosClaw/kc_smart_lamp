# kc_smart_lamp — Repo Conventions

## Scope

**This repo covers**：
- ESP32 firmware（NimBLE GATT service + FastLED 驅動 WS2812B）
- Host BLE client（Python `bleak` 寫 GATT characteristics — CLI + FastAPI Web UI）
- iOS app（SwiftUI + CoreBluetooth 控 BLE GATT）
- Custom GATT service / characteristic spec
- 3D-printed enclosure（OpenSCAD `.scad` source）
- Hardware BOM、配線圖、組裝 SOP

**This repo does NOT cover**：
- 任何工作場域的 backend code、客戶整合邏輯
- 任何外部專案的 code 或 spec 複製

**為什麼切開**：個人 side project，自費硬體 + 下班時間開發。雇主可能有「在職期間業務相關職務發明」條款 — 嚴格守 scope 邊界以避免智財爭議。Owner 翻過 offer letter 確認條款後再決定是否轉 public。

## Coding Convention

- 開發語言：Embedded C/C++（firmware）+ Python 3.12+（host）+ Swift 5+ / SwiftUI（iOS）+ OpenSCAD（CAD）
- 註解 / 文件 / commit message：以英文為主（CLAUDE.md / README_zh.md / docs 中文 OK）
- snake_case 命名；不用駝峰
- Firmware 不用 Arduino IDE → PlatformIO（reproducible build）
- Host client 走 `bleak` async / await，不用 deprecated lib
- 3D CAD 用 OpenSCAD（純文字 .scad）— 不上 Fusion 360 / GUI tool

## Commit Format

`Category: lowercase description` — categories（依 prep-repo skill）：

- `Init:` 初始 commit / scaffold
- `Core:` 核心功能變更（firmware / host client / GATT spec）
- `Docs:` 文件變更
- `fix:` bug 修復
- `fix(security):` 安全修復
- `Build:` build / CI / Docker 變更
- `CAD:` 3D 模型變更（OpenSCAD `.scad`）

不掛 `Co-Authored-By` 行（依 prep-repo §7）。

## Git 紀律

- **絕不**用 `git add -A` / `git add .`，只 add 具體檔案
- 不 push 任何 secret / personal info / 內部 IP
- 任何「公司」相關字眼若在 commit / code 出現 = 紅旗，停下來重 frame
- 每次推 GitHub 前跑 prep-repo §6 sensitive data scan

## Architecture Decisions

寫進 `docs/decisions/`（ADR 風格），主要決定：

- 為何 ESP32 而非 NanoPi（見 `docs/nanopi_research.md`）
- 為何 BLE GATT 而非 USB serial / WiFi
- 為何 OpenSCAD 而非 Fusion 360
- 為何 WS2812B 而非市售燈泡

## Status / Roadmap

Status 在 README badge 表達。Milestone 用 GitHub Issues + Project board 管理（TBD）。
