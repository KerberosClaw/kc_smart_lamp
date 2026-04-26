# kc_smart_lamp — SwiftUI Reference Implementation

設計師交付的 SwiftUI 參考實作。9 個 .swift 檔，無第三方依賴，未來在 Xcode 開 iOS App project 時把這些 Source 加入即可。

## 檔案

| 檔案 | 用途 |
|---|---|
| `LampApp.swift` | App entry point + 顏色 / 狀態 model |
| `LampScreen.swift` | 主畫面 (single screen，組合所有元件) |
| `ColorWheelView.swift` | HSV 色盤 (hero element) |
| `BrightnessSlider.swift` | 亮度滑桿 |
| `PresetChip.swift` | 三個 preset chip + `PresetRow` 容器（兩 type 同檔） |
| `ApplyButton.swift` | 主 CTA |
| `PowerToggleRow.swift` | Power 開關 row |
| `ConnectionPill.swift` | 連線狀態 dot + label |
| `LampBLEClient.swift` | CoreBluetooth client (對應 GATT spec 5-byte LAMP_STATE) |

## 架構

依 [ADR 0003 thin-client](../docs/decisions/0003-thin-client-architecture.md)：

- App 是 dumb client，**唯一**對 lamp 做的事情是 read / write 5 bytes
- 沒有 scene engine、沒有 schedule，這些在 Mac host 端跑
- BLE write payload：`[power, R, G, B, brightness]` (見 `LampBLEClient.set_state`)

## 視覺方向

- **Dark mode only**，黑底
- **動態主色** = lamp 當前 RGB color（app 視覺隨 lamp 變化）
- **大量半透明 frosted glass 卡片**，subtle blur + tint
- **大圓角**：卡片 r=24-26，按鈕 r=18，chip r=14
- **動畫節奏**：spring response 0.4, damping 0.75 — smooth 但不 bouncy

## Build 提示

- iOS 17+ (用 `Observable` + 新 SwiftUI APIs)
- iPhone only，直式 only
- 字型純 SF Pro 系統字
- 無第三方 dep
