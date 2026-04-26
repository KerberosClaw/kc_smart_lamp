# ADR 0006: Web service v1.1 — BLE reconnect with exponential backoff

**Status**: Accepted
**Date**: 2026-04-26
**Supersedes**: `docs/gatt_spec.md` Connection lifecycle (v1) 「Reconnect 邏輯 v1 不做」**僅針對 web service**；CLI 維持 v1 行為（一次性命令，不 reconnect）

## Context

`gatt_spec.md` v1 寫「reconnect 邏輯 v1 不做（連不上 → 報錯給 user）」。對 CLI 一次性命令這成立 — 一條命令就斷，下次再 scan。

但 web service (`smart-lamp-web`) 是 long-running daemon，現實中會遇到：

- 開機自啟（launchd / systemd / Windows Task Scheduler）後 lamp 還沒接電 → server 不能直接 fail
- USB cable 鬆掉 / lamp 斷電一秒鐘 / 距離過遠暫時掉藍芽
- Host 睡眠喚醒（macOS power nap / Windows sleep）後 BLE stack 重新初始化
- Kernel update / power loss reboot 後 service 自啟，但 lamp 可能還沒 ready

長期 daemon 跟一次性 CLI 是不同 lifecycle 需求。User 不該為了讓燈再次能 control 而 ssh 進去手動重啟 daemon。

## Options Considered

| 選項 | 改動位置 | 對 CLI 影響 | 複雜度 |
|---|---|---|---|
| A. 改 `LampClient` 加 reconnect | `ble.py` | CLI 也會 reconnect（多餘） | 中（要 detection + backoff） |
| B. 包一層 `LampSession` 類別 | `lamp_client/session.py` 新增 | 無 | 中（額外類別） |
| **C. Web service 層 retry loop** ⭐ | `web.py` 加 background task | 無 | 低（~30 行 inline） |

## Decision

採用 **C 方案**。`LampClient` 維持「一次 connect、一或多次 write、disconnect」的乾淨 BLE primitive。`web.py` 加一個 background task `_maintain_connection`：

1. 啟動時 scan + connect，失敗就退避重試
2. 連線後輪詢 `client.is_connected`（`LampClient` 新增 property），偵測掉線
3. 掉線後從步驟 1 重來
4. shutdown 信號（`asyncio.Event`）觸發乾淨退出

退避策略：初始 2 秒，每次失敗 ×2，上限 60 秒。連線成功 reset 為 2 秒。
偵測週期：1 秒輪詢 `is_connected`。

## Rationale

1. **Separation of concerns**：BLE primitive 保持簡單，lifecycle 複雜度上抬到 service 層。對應 ADR 0003「dumb actuator + smart host」哲學的 host 內部分層。
2. **CLI 一次性語意維持**：`smart-lamp --hex FF0000 --on` 想要的是「立刻打、打不通就報錯」，不是「等到燈出現再打」。CLI codepath 完全不動。
3. **測試隔離**：BLE primitive 的 unit test 不受 backoff timer 干擾。
4. **簡單路線贏**：A 改動 BLE primitive 表面積大；B 多一個類別在 session.py，本階段 scope 不需要可重用的 session 抽象。C 30 行 inline 解決問題，跟 web.py 既有 module-level state pattern 一致。

## Consequences

### 正面

- Server 啟動不卡 — lamp 不在也照常 listen，請求收到 503「lamp not connected」直到連上
- 連線飄掉自動恢復，~1-60 秒內復原
- CLI 行為不變
- `LampClient.is_connected` property 加進 public API，未來其他 long-running client（iOS app future Mac port、其他自動化 hook 等）也可重用同 pattern

### 負面

- ~1 秒掉線偵測延遲（health poll interval）— 對 BLE write latency 30-50ms 量級可接受
- web.py 多一個 background task，shutdown path 多一步（已用 `asyncio.Event` 處理）
- 重連期間 in-flight write 會以 `RuntimeError`（`_require()` 檢查失敗）或 bleak 內部 exception 形式拋給 endpoint handler → 500 response。Client 需 catch 503 + 5xx 都當「lamp 暫時不可用」處理。

## Supersedes (partial)

`docs/gatt_spec.md` 「Reconnect 邏輯：v1 不做」**僅對 web service** supersede 為 v1.1 reconnect。CLI v1 行為保留。
