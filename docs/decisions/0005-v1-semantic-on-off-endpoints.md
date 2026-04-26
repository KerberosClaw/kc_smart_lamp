# ADR 0005: v1 web API 簡化 — 只暴露 on/off 語意端點

**Status**: Accepted
**Date**: 2026-04-26

## Context

`smart-lamp-web` v0.1 只暴露 `/api/set_state`，要求 client 自構完整 5-byte state（power + RGB + brightness）。對 web UI 自己 OK（每次按按鈕本來就讀 sliders 算好），但對其他想做「快速觸發」的 client 不友善：

- iOS Siri Shortcut「開燈」要嘛 hardcode 死「255,255,255,100」、要嘛先 read 當前 state 再 toggle
- macOS Raycast / Alfred quick action 同樣問題
- 任何 hook（Home Assistant / Node-RED / Hammerspoon / 自寫 watchdog 觸發燈號）— 「turn on / turn off」是最高頻 intent，不該每次發 5 欄位

需要一個語意層：「打開燈 / 關掉燈」直接表達 intent，不要求 client 知道 RGB 數字。

## Options Considered

| 選項 | API surface | 整合複雜度 | 行為確定性 |
|---|---|---|---|
| A. 完整語意 API | `/api/set_color {name}` + 多語色名 alias + `/api/set_brightness` | 高（色名 NLU + 多語對齊 + 連動測） | 中（解析歧義） |
| **B. 固定 on/off** ⭐ | `/api/lamp/on`（白光 100%）+ `/api/lamp/off` | 極低（單一固定行為，client 不傳 body） | 高 |
| C. 不加新端點 | 維持 `/api/set_state` | 低 | 中（client 要自構 payload，違反語意分層） |

## Decision

採用 **B 方案**。v1 web API 加兩個固定行為端點：

- `POST /api/lamp/on` → `LampState(power=True, R=255, G=255, B=255, brightness=100)`
- `POST /api/lamp/off` → `LampState(power=False, R=0, G=0, B=0, brightness=0)`

`/api/set_state` 保留，CLI / web UI / 進階 client 仍可全 5-byte 控制。

## Rationale

1. **「開燈 = 白光 vs 恢復上次色」選白光**：v1 沒有色 intent，「恢復上次色」無 use case；上電預設值未定義，避免「第一次開燈顏色不對」的 surprise。
2. **行為單一可預期**：「開燈 = 白光最亮 / 關燈 = 滅」一句話講完，整合方測試也單純。
3. **規避 NLU 歧義**：色名解析 / 亮度語意（「purple 是紫還是紅」、「暗一點是 -10% 還是 -30%」）的歧義面整套不用接。v2 真要做的時候再評估。
4. **未來路徑明確**：v2 加 `/api/set_color {name}` + 多語色名 alias 是本 ADR 的擴展，不是棄掉。

## Consequences

### 正面

- 任何 client（Siri Shortcut / Raycast / Alfred / 自寫 voice trigger / 未來 home automation hook）整合三秒：發 POST 不帶 body
- `/api/set_state` 維持原行為，CLI / iOS app / web UI 不受影響

### 負面

- 「白光 100%」視覺平淡。若想要 fancy 效果，firmware 開機可加 boot 動畫，「開燈」打開的是穩定主光源
- v2 擴展時要新增端點而非擴 on/off — 這跟 `set_color` 路徑天然分層，不算 debt

## Supersedes

無 — 本 ADR 形同凍結 v1 web API surface 為三個端點：`set_state` / `lamp/on` / `lamp/off`。
