# ADR 0007: smart home 生態整合 — 暫緩，傾向 HomeSpan 直連 HomeKit

**Status**: Deferred（紀錄分析結論與傾向，實作觸發條件待定）
**Date**: 2026-04-30

## Context

現況 `kc_smart_lamp` 走純 BLE GATT，控制端為 Python CLI / FastAPI Web UI / iOS app。設計理念：no app, no cloud, no vendor lock — 桌邊距離、本地控制、不依賴 hub。

ESP32-S3 N16R8（16MB Flash + 8MB PSRAM + Wi-Fi/BLE 雙模）硬體規格其實是 Matter 開發甜蜜點，跑 Matter stack 綽綽有餘。隨之而來的問題是：要不要為了「跟 Apple Home / Google Home / Alexa 整合」而加上 Matter？

本 ADR 紀錄三條候選路線比較與當前傾向，作為日後（如有需要）動手前的依據。

## Options Considered

| 選項 | 整合範圍 | 需要的 hub / 基礎設施 | 開發複雜度 | 認證成本 |
|---|---|---|---|---|
| A. 維持純 BLE（現狀） | 自有 client only | 無 | 低（已完成） | 無 |
| B. Matter over Wi-Fi + HA Bridge | 跨生態（Apple / Google / Alexa） | Home Assistant（自架）+ commissioning hub | 高（Matter stack + commissioning UX + partition table） | test DAC 免費，正式 CSA 認證 USD $7000+/年 |
| C. HomeSpan 直連 HomeKit | 僅 Apple Home | HomePod mini / Apple TV（BLE peripheral 角色 hub） | 中（HAP-only，比 Matter 輕） | 無（HAP 2019 開源） |

## Decision

**暫緩升級，現階段維持選項 A（純 BLE）**。若未來決定動手，**傾向選項 C（HomeSpan）**而非 B（Matter + HA Bridge）。觸發實作的條件：

- 出現「自己想用 Apple Home 控桌燈」的具體 daily-use 需求（目前沒有）
- 或加入電池供電感測器類型裝置（屆時連硬體選型一起重新評估，可能換 ESP32-C6 走 Thread）

## Rationale

### 為何不走 Matter（選項 B）

1. **跨生態的價值對個人桌燈不成立** — Matter 的賣點是「一個裝置進所有生態」。本專案 use case 是自己 + 少數朋友、桌邊距離、USB 供電，跨生態需求不存在。
2. **Matter + HA Bridge 路線打臉本專案 design philosophy** — 「no cloud, no vendor lock」變成「請使用者先裝一台 Home Assistant server」，從用 Python script 配對退化成要先架 HA。
3. **雙協定並存對 side project 是過度設計** — Matter stack + NimBLE 同時跑要處理 partition table、commissioning UX、模式切換、BLE/Wi-Fi coexist 延遲劣化。原始討論預估 1-2 週，實際很容易滾到 4-6 週。
4. **CSA 認證對 hobbyist 不可行** — USD $7000/年起跳；test DAC 在 Apple Home 直接被拒，要繞 HA Bridge 才能進。

### 為何傾向 HomeSpan（選項 C，若要動手）

1. **HAP 2019 起 Apple 開源（Non-Commercial）** — 合法、免認證、不踩 Apple 法務地雷。
2. **比 Matter 輕一個量級** — 不用 commissioning server、不用 HA、HomePod mini 就是 hub。開發複雜度從「Matter stack 全套」降到「HAP-only」。
3. **「只進 Apple Home」對本專案是 feature not bug** — design philosophy 本來就反生態綁定，但若使用者本人就是 Apple 生態，HomeSpan 直連反而最忠於 no-cloud 精神（HomeKit 是 local-first，不像 Google 早期那樣強制過雲）。
4. **與現有 BLE 路線可乾淨切換**，不需要雙協定並存的 partition / coexist 工程開銷（HomeSpan 走 Wi-Fi，BLE 模式可以靠 firmware 編譯 flag 切換不同 build）。

### 為何現在暫緩

- 沒有自己會用的 daily-use 場景驅動。為了「能進 Apple Home」這個假設性需求動工，違反 Karpathy goal-driven 紀律。
- 桌燈專案核心價值（BLE local control + Web API + iOS app）已自洽，加 HomeKit 是擴展不是補洞。

## Consequences

### 正面（維持現狀）

- 韌體 / host / iOS 三條路線繼續穩定迭代，不被 Matter / HomeKit stack 打斷
- 保留「需求出現再動手」的 optionality，硬體完全相容（ESP32-S3 跑 Matter 或 HomeSpan 都沒問題）

### 負面

- 暫時無法在 Apple Home / Google Home 看到燈，需透過自有 iOS app 或 Web UI 控制
- 若 future-self 忘記本 ADR 的分析，可能重複跑一次「該不該上 Matter」的評估循環

## Notes — Matter / Thread / HomeKit 技術備忘

留下幾個之後重啟評估時不用重查的事實：

- **Matter 是應用層 / Thread 是網路層**，不互斥。Matter over Wi-Fi 是本專案唯一合理選項（USB 供電、ESP32-S3 沒 802.15.4 radio）。
- **未來做電池感測器**：ESP32-C6（Wi-Fi 6 + BLE 5 + Thread 一顆通吃）才是合理硬體選型，跟桌燈分開評估。
- **Apple Home 對 Matter 認證最嚴**：test DAC 拒絕，必須 PAA 鏈簽發的 DAC。HA HomeKit Bridge 路線繞過這點是因為 Apple 驗證的是 HA 的 bridge 不是燈。
- **HAP 開源條款**：Non-Commercial Use License。個人 / 開源專案 OK，商業化要重新評估。
