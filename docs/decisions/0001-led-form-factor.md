# ADR 0001: LED 硬體形式 — 8 LED Ring

**Status**: Accepted (sourcing pivoted to 蝦皮 2026-04-26)
**Date**: 2026-04-26
**Supersedes**: 早期 NanoPi 路線採購清單第一項「WS2812B LED strip 1m 60 LED 5V」（見 [ADR 0004](0004-no-nanopi.md)）

## Context

Use case 收斂：

- **5 顆獨立可控 RGB LED**
- 主要應用：**狀態指示燈**（PR 紅黃綠 / 降雨機率視覺化等），**非環境照明**
- Owner 零硬體 / 焊接經驗（見 ADR 0002）

需要決定 WS2812B 的物理形式（form factor）。

## Options Considered

| 選項 | 顆數 | 浪費 | 焊接需求 | 對 use case 契合度 |
|---|---|---|---|---|
| 裸晶片 5050 SMD（10 顆裝） | 10 | 0（5 顆備品） | 高（SMD 手焊） | ✓，但要會焊 |
| 1m 60-LED 燈條 | 60 | 55 | 中（焊 3 條粗線） | 直線排列契合 PR pipeline |
| **8 LED Ring** | **8** | **3** | **0（買預焊版）** | **★ 環形對狀態燈 UX 最佳** |
| 12 LED Ring | 12 | 7 | 0 | OK 但浪費較多 |
| 16 LED Ring | 16 | 11 | 0 | 體積偏大 |
| 24 LED Ring | 24 | 19 | 0 | 浪費過多 |
| Jewel 7（1 中心 + 6 周圍） | 7 | 2 | 0 | 中心 + 周圍可分主次狀態 |
| Stick 8（直線） | 8 | 3 | 0 | 直線版替代方案 |

## Decision

採用 **WS2812B 8 LED Ring（預焊杜邦線版）**。

備案順序：8 Ring → Jewel 7 → Stick 8 → 才考慮燈條剪段。

## Rationale

1. **環形排列對狀態燈 UX 天然契合**
   - PR 5 stage：環形像 pipeline 流程圖
   - 降雨機率 0–100%：8 顆環形剛好做「鐘錶式」進度（每顆 12.5%，視覺滿一圈 = 100%），這個直接打贏 5 顆直線版
   - 8 顆比 5 顆多了「整圈滿」的語意
2. **體積適中** — 外徑約 32mm（50 元硬幣大），桌上不顯眼，3D 外殼也好做
3. **零焊接門檻** — Ring 板出廠多含預焊三色杜邦線，直接插 ESP32 + 麵包板即可
4. **浪費可控** — 8 顆中用 5 顆，浪費 3 顆；對比 16/24 Ring 浪費 11/19 顆，或燈條浪費 55 顆，是合理配置
5. **彈性保留** — 沒用到的 3 顆可做：總狀態（中心式）/ 環境光暈 / future use case 擴展

## Consequences

### 正面

- bring-up 階段採購門檻最低（不用焊）
- 兩個主要 use case（PR 狀態 / 降雨機率）都能視覺化得體

### 負面

- 「直線」狀態 use case（如 PR pipeline 直視）會看起來繞環，不像傳統 CI 介面
- 將來若想做 30 顆漸變光暈，要另外採購（Ring 沒辦法擴展）
- `README_zh.md` 架構圖中的「WS2812B 可定址 RGB 燈條」描述要更新為「WS2812B 8-LED Ring」（待採購到貨後再改）

### 後續動作

- [x] 採購：實體店確認 8 LED Ring 庫存 — **無預焊版**，改走蝦皮
- [ ] 更新 `README_zh.md` 架構圖 LED 描述（Ring 到貨後對齊）
- [ ] firmware 設計：5 顆主用 + 3 顆預設黑（保留 mode 切換可全亮）

---

## Update 2026-04-26 — Procurement

- **Sourcing channel changed**：8 LED Ring 改走蝦皮（實體店家難確認「真的預焊」vs「焊盤裸露」），預估 2-3 天到貨
- **Decision unchanged**：仍是 8 LED Ring 預焊版
- **Bonus**：實買的 ESP32-S3-WROOM-1 N16R8 dev board 內建一顆 WS2812 RGB LED（同協定），可在 Ring 到貨前先驗整條 BLE → FastLED → WS2812 chain（[dev_setup.md M4a](../dev_setup.md)），M4b 切外接 Ring 只改 `NUM_LEDS` 跟 data pin 兩個常數
