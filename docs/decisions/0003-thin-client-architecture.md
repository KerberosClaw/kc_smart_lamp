# ADR 0003: Thin-client architecture — host runs all logic, firmware stays dumb

**Status**: Accepted
**Date**: 2026-04-26
**Validated**: 2026-04-26（M2 + M3 + M4a end-to-end 通過，三個 client 同時驗證）

## Context

M3 驗證通過後（單一 5-byte `LAMP_STATE` characteristic 端到端 work），冒出一個 architectural 問題：「**未來功能（effect / scene / schedule / 動畫）寫在哪？**」

兩條路：

- **A. Smart firmware**：firmware 內建效果引擎 / scheduler，client 只下高階指令（`set_scene("breathing_red")`）
- **B. Thin-client + dumb actuator**：firmware 永遠只解 5 bytes 點 LED，所有「智能」在 host 上跑

## Options considered

| 選項 | 邏輯位置 | Pros | Cons |
|---|---|---|---|
| A. Smart firmware | 韌體內建 effect / schedule / scene engine | Lamp 不靠 host 也能自主動作 | 每次新功能 = 重燒；firmware 複雜化；ESP32 上 debug 比 Python 難 10 倍 |
| **B. Thin-client + dumb actuator** ⭐ | 韌體：5-byte state setter only。Host：所有「智能」在 Python 跑 | 新功能秒迭代不用重燒；多 client 並存（CLI / Web / iOS）；韌體保持小 + 穩 | Host 關機時 lamp 凍在最後狀態 |

## Decision

採用 **B 方案**。Firmware 只接受 `LAMP_STATE` 5-byte write；所有更高階行為（Pomodoro 計時、PR 狀態、行事曆變暗、呼吸燈、降雨色、色溫漸變、音樂同步…）都當 Python script 跑，呼叫 `LampClient.set_state()`。

## Rationale

1. **迭代不用重燒** — 新功能 = Python edit。對比 firmware：rebuild → 手動 download mode → flash → reset。週期從「秒」變「半分鐘」。
2. **Multi-client 已經 work** — 同一 characteristic 接受 CLI / Web / iPhone nRF Connect / 未來 SwiftUI app / 任何 BLE 工具的 write。**韌體不需要知道是誰寫的**。**2026-04-26 已驗證三個 client（macOS Python CLI、FastAPI Web UI、iPhone nRF Connect）並存無衝突**。
3. **Firmware 可靠性** — Dumb actuator 表面積小（~100 行 C++）。Code 越少，crash / watchdog / heap corruption 機會越少。把 effect / scheduler 塞進去就要管 timer、async state machine、persistence — 維護成本陡升。
4. **Debug 不對稱性** — Python `print()` + breakpoint vs. ESP32 Serial + 物理 reset。Python 迭代速度快一個量級。
5. **Use case 對得上** — 桌邊狀態燈，user 在 desk 用主機時 Mac 都在開機。Lamp 沒人在的時候本來就不需要做事。

## Consequences

### 正面

- 新「智能」功能 = Python script。零韌體變動。
- 多個 controller 可同時針對同 lamp（已驗證）。
- 韌體小（540 KB / flash 16%）→ 未來加 GATT 留充足 headroom。
- iOS app（Swift + CoreBluetooth）也適用同架構 — 未來寫一個就跟現有 Python client 平級。

### 負面

- Host 關機時 lamp 凍在最後狀態，不會自主呼吸 / 顯示時鐘 / ambient。
- 需要精準時序的 effect（例如 60 fps 動畫）受 BLE write 延遲約束（~30-50 ms / write）。對「呼吸燈」這種 1 Hz 等級沒問題，60 fps 流暢漸變要在 firmware 端做 LED interpolation（這就破純度了，待真有需求再想）。

### 對現有文件的影響

- [`docs/gatt_spec.md`](../gatt_spec.md) 「Future characteristics」list **拿掉 `EFFECT_MODE` 跟 `SCHEDULE`** — 它們不是「之後做」，而是「不會做」。剩 `LAMP_INFO`（infrastructure：firmware version 識別）跟 `OTA_TRIGGER`（infrastructure：韌體更新），都不是 feature。
- `host/lamp_client/` 是未來「智能」邏輯累積的地方。模式可能會浮現（`effects/`、`schedules/`、`integrations/`）— 等 script 多了再 refactor。

## Reversibility

如果有天 host-only 真的變成限制（例如「我希望 Mac 關了 lamp 還能呼吸」），逃生口：

1. **加一台 always-on 小機器**（Raspberry Pi / NanoPi）跑 Python lib，lamp GATT spec 不動
2. **或補新的 GATT characteristics**（`EFFECT_MODE`、`SCHEDULE`）給自主行為。**現有 thin-client 平行繼續 work**（同 service 加新 characteristic 不破壞舊 client）

兩條都不需要破壞現在這版 v1。
