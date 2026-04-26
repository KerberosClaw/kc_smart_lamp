# GATT Specification — kc_smart_lamp

**Version**: 0.1.0
**Status**: Draft (not yet validated against hardware)
**Date**: 2026-04-26

> **English summary:** Wire-level BLE GATT specification for kc_smart_lamp. Defines a single service exposing one characteristic (`LAMP_STATE`) — a 5-byte write atomically updates power, RGB color, and brightness. The whole protocol fits in a coffee break.

## Overview

kc_smart_lamp 暴露**一個** BLE GATT service、**一個** characteristic（`LAMP_STATE`）。單次 5-byte write 就 atomically 更新整個 lamp 狀態（power + RGB + brightness）。

**為什麼用單一 5-byte characteristic 而不是拆成 power / rgb / brightness 三個**：

1. **匹配 onSubmit UX** — User 按按鈕的當下「所有設定一起套用」，1 次 BLE write 對映自然
2. **延遲最低** — 單一 write ~30-50ms，三個 write ~90-150ms
3. **不會出現 ghost state** — 三個 write 中途斷線，會卡在「燈關了但顏色變到一半」這種半成品狀態；單一原子 write 不會

副作用：要讀「目前亮度多少」這種單一欄位，client 要 read 整個 5 bytes 自己 parse。對我們不是問題 — UI 永遠 read-modify-write 整個 state。

## Service

| 項目 | 值 |
|---|---|
| Name | `kc_smart_lamp` |
| Service UUID | `2f421b7d-41dd-4de6-a19a-1194b4d04361` |
| Advertised name | `kc_smart_lamp` |

## Characteristic: `LAMP_STATE`

| 項目 | 值 |
|---|---|
| UUID | `2f421b7d-41dd-4de6-a19a-a2a6dae023f9` |
| Properties | `read`, `write (with response)` |
| Length | 5 bytes |

### Byte layout

| Byte | Field | Range | Meaning |
|---|---|---|---|
| 0 | `power` | 0 or 1 | 0 = off, 1 = on |
| 1 | `R` | 0–255 | Red component |
| 2 | `G` | 0–255 | Green component |
| 3 | `B` | 0–255 | Blue component |
| 4 | `brightness` | 0–100 | Brightness percent (0 = dark, 100 = full) |

### Write semantics

Client 寫 5 bytes。Firmware：

1. **驗證 length == 5**（不是就 reject，不更新狀態）
2. **Clamp `brightness` 到 0–100**
3. **更新內部狀態**：保存 5 個欄位
4. **套用到 LED**：
   - 若 `power == 0`：LED 熄滅（`FastLED.clear()`），但**記憶體保留 R/G/B/brightness** 給下次 `power == 1` 用
   - 若 `power == 1`：LED 顯示 `(R, G, B)`，亮度 scale 為 `brightness / 100`

**範例**：write `(power=0, R=255, G=0, B=0, brightness=100)` → 燈關掉但記住「上次是紅色 100%」。下次 write `(power=1, R=255, G=0, B=0, brightness=100)`（或任何 power=1 的 write）→ 燈恢復紅色 100%。

> **Off 行為的 ADR**：選方案 A（firmware 層處理 off，記憶體保留設定），不是方案 B（power=0 等同 brightness=0）。理由：方案 A 比較符合「電源開關」直覺，且 future button 控制 on/off 時不需要 client 重發 RGB。

### Read semantics

Client read → 回傳**最後一次寫入的 5 bytes**。

> **Future caveat**：當 firmware 將來加上實體按鈕 / 感測器輸入時，「最後寫入」可能跟「目前實際狀態」不同步。屆時 spec 要明確 read = 「目前實際狀態」，firmware 要在內部狀態變化時主動 `setValue()`。**v1 沒這個分歧**（目前狀態變化只有 BLE write 一個來源）。

## ⚠️ Future: client-side `status` command（已 memo，v1 不暴露）

**Lib 層 (`LampClient.get_state()`) 從第一天就完整實作 read 路徑**。但 **CLI 跟 Web v1 不暴露 status 指令**，等下面的 use case 真的要用再 wire（10 行 code 的事）。

**為什麼要保留這個 hook**：使用情境是「**保留某些欄位，只改其他**」：

- 「**保留顏色，只調亮度**」：UI 先 read 當前 RGB → 套用新 brightness → write 完整 5 bytes
- 「**保留色 / 亮度，只切 on/off**」：UI 先 read 當前狀態 → 翻 power byte → write 完整 5 bytes
- 「**狀態查詢**」：CLI `smart-lamp status` debug 用

**對應的 client 改動**（v1.1 或更晚做）：

| 元件 | 變更 |
|---|---|
| `LampClient.get_state()` | ✅ 已實作（無變更） |
| `cli.py` | 新增 `status` subcommand，讀 state 印表格 |
| `web.py` | 新增 `GET /api/state`（return 當前 state JSON） |
| `static/index.html` | 頁面載入時 `fetch /api/state` 預填色盤 / slider；submit 前 client 端可 merge |

## Connection lifecycle (v1)

- Client scan advertised name `kc_smart_lamp`，預設 timeout 5 秒
- Client connect via 標準 BLE GATT，無 bonding（Just Works）
- Connection 維持期間：CLI 一次性命令連完即斷；Web server 啟動時連、關閉時斷
- Reconnect 邏輯：v1 不做（連不上 → 報錯給 user），v1.1 加 retry / keep-alive

## Future characteristics（infrastructure-only，不為 feature 而加）

依 [ADR 0003 — Thin-client architecture](decisions/0003-thin-client-architecture.md)，**feature 邏輯（effects / scenes / schedules / 動畫等）永遠在 host 上實作，不上 firmware**。所以原本列為 future 的 `EFFECT_MODE` / `SCHEDULE` 已從本 list 移除 — 它們不是「之後做」，而是「不會做」。

剩兩個 future characteristics 都是 infrastructure，不是 feature：

| 候選 | 用途 | 為何不算 feature |
|---|---|---|
| `LAMP_INFO` (read) | firmware version / MAC / hw rev | 純 metadata，host 端 debug / 識別用 |
| `OTA_TRIGGER` (write) | 觸發 OTA 韌體更新 | 維護用，不是 user-facing 功能 |

加在同 service 下面，不破壞 v1 client 兼容性。
