# kc_smart_lamp iOS App

Native SwiftUI iOS app controlling the lamp via BLE. Visual direction defined in [`docs/app_design_brief.md`](../docs/app_design_brief.md), implementation drop from designer.

## 結構

```
ios/
├── kc_smart_lamp.xcodeproj/      # Xcode project（用這個開）
└── kc_smart_lamp/                # Source group
    ├── LampApp.swift             # @main entry + LampState model + HSV math + Design tokens
    ├── LampScreen.swift          # 主畫面 (single screen, 組合所有元件)
    ├── ColorWheelView.swift      # HSV 色盤 (hero element)
    ├── BrightnessSlider.swift    # 亮度滑桿
    ├── PresetChip.swift          # 三個 preset chip + `PresetRow` 容器（兩 type 同檔）
    ├── ApplyButton.swift         # 主 CTA
    ├── PowerToggleRow.swift      # Power 開關 row
    ├── ConnectionPill.swift      # 連線狀態 dot + label
    ├── LampBLEClient.swift       # CoreBluetooth client (對應 GATT spec 5-byte LAMP_STATE)
    └── Assets.xcassets/          # App icon + accent color
```

## Build / Run

```
1. Xcode 開 ios/kc_smart_lamp.xcodeproj
2. 選 iPhone（實體 device，simulator 沒 BLE 廣播）
3. Cmd+R
```

第一次跑會跳 BLE 權限對話框，按允許。

> 燒錄 firmware 後，把板子接電源（Mac 不用插），iPhone 在 ~10m 內就掃得到 advertise 的 `kc_smart_lamp`。

## 架構

依 [ADR 0003 thin-client](../docs/decisions/0003-thin-client-architecture.md)：

- App 是 dumb client，**唯一**對 lamp 做的事情是 read / write 5 bytes
- 沒有 scene engine、沒有 schedule，這些在 Mac host 端跑
- BLE write payload：`[power, R, G, B, brightness]`（見 `LampBLEClient.write`）
- BLE protocol 跟 [Python host (`host/`)](../host/) 跟 [web UI (`host/lamp_client/static/`)](../host/lamp_client/static/) 共用同一份 [GATT spec](../docs/gatt_spec.md)

## 視覺方向

- **Dark mode only**，黑底
- **動態主色** = lamp 當前 RGB color（app 視覺隨 lamp 變化）
- **大量半透明 frosted glass 卡片**，subtle blur + tint
- **大圓角**：卡片 r=24-26，按鈕 r=18，chip r=14
- **動畫節奏**：spring response 0.4, damping 0.75 — smooth 但不 bouncy

## Build 環境

- iOS 17+（用 `@Observable` + 新 SwiftUI APIs）
- iPhone only，直式 only
- 字型純 SF Pro 系統字
- 無第三方 dep
- Bundle ID 跟 signing：依各 dev 帳號
