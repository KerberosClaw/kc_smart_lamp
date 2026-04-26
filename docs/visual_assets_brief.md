# Visual Assets Brief — App Icon + Launch Screen

**Status**: Draft（給設計師看的需求）
**Date**: 2026-04-26
**For**: 之前做 iOS app + web UI 的同一位設計師

> **English summary:** Companion brief to `app_design_brief.md`, scoped specifically to two iOS-required visual assets — app icon and launch screen. Inherits product positioning, mood, and palette from the main brief; this document only adds delivery specs and asset-specific direction.

> 這份是 [`app_design_brief.md`](app_design_brief.md) 的補件，專門處理 **app icon** 跟 **launch screen** 兩個 iOS 必要視覺資產。背景 / mood / 配色繼承上一份 brief，這裡只列規格與這次特定需求。

---

## 1. Goal

iOS app 上架 / 給朋友看的時候必需的兩個視覺資產：

1. **App Icon**：手機桌面那顆圖示
2. **Launch Screen**：app 啟動的 0.5-1 秒過渡畫面

兩者風格要一致，且延續上次 brief 的 **Tesla 工業 + 黑底 + 玻璃感** 整體調性。

---

## 2. Reference

| 來源 | 用途 |
|---|---|
| Owner GitHub 大頭貼：[ TODO 貼 URL ] | **主要 anchor** — 設計師延伸這個風格做 |
| [`app_design_brief.md`](app_design_brief.md) 第 5 節 | 整體 style direction（Tesla mood / 動態主色 / 大圓角） |
| 上次的 iOS 實作 `ios/kc_smart_lamp/` | 看 SwiftUI 已實裝的視覺，icon 不要跟 app 內 UI 衝突 |

---

## 3. App Icon

### 規格（iOS 系統要求）

| 項 | 規格 |
|---|---|
| Format | PNG |
| 解析度 | **1024 × 1024**（Xcode 會自動生其他 size） |
| 透明背景 | ❌ **不允許**（Apple 拒上架） |
| 圓角 | ❌ **不要自己加**（iOS 自動套圓角 mask） |
| Color profile | sRGB |

### 風格方向

延續 GitHub 大頭貼 + Tesla 工業 mood：

- **背景**：純黑（#000）或極深灰（#0A0A0A）
- **主視覺建議**：一顆發光圓 LED / 燈泡 / 抽象光點，搭配微 radial glow
- **配色**：黑底 + 一個強調色發光（暖橘 #FFB35A 或冷藍都可，跟 app 內 dynamic accent 同 family）
- **不要**：卡通風 / 漸層撞色 / 文字（icon 內不要有 "lamp" / "kc" 字）
- **可以**：抽象幾何 / 微 gradient / 玻璃感 / 工業細節

### Deliverable

**至少 2 個 variant** 我選一個：

| Variant | 描述（建議） |
|---|---|
| A | 黑底 + 暖橘發光燈泡 |
| B | 黑底 + 冷白發光圓點 |
| （可選）C | 設計師創意自由發揮的版本 |

每個 variant 提供 1024×1024 PNG 即可。

---

## 4. Launch Screen

### iOS Launch Screen 限制（先講清楚避免設計過頭）

iOS 限制比想像多，**設計師需要知道的**：

- **不能有動畫** — 純靜態圖
- **不能放可變文字** — 不能有「Loading...」「Welcome」等動態字
- **不能執行任何 code** — 連讀本地時間都不行
- **顯示時間極短**：~0.5 秒，user 看到瞬間就轉到主畫面
- **不能 brand 過頭** — 不是廣告畫面，是「app 馬上要起來了」的視覺承接

### 我們選哪種實作

兩種做法選一個（**設計師建議我用哪個**）：

| 做法 | Pros | Cons |
|---|---|---|
| **A. Info.plist + 純背景色 + 一張置中 PNG** | 簡單、Xcode 自動處理、一個 PNG 搞定 | 自由度低 |
| B. LaunchScreen.storyboard | 自由 layout（位置、多元件） | 要在 Xcode 內做、設計師不一定熟 |

我預設走 **A**。

### 規格

| 項 | 規格 |
|---|---|
| 背景色 | **#000 純黑**（跟 app main screen ZStack 第一層同色 → 過渡無縫，user 不會感覺「黑掉」） |
| 中間視覺 | App icon 的**簡化版**（line art / monochrome / 縮小版），不要彩色 icon 直接搬上來 |
| 視覺尺寸 | 中間 PNG 約 200×200 pt（中央偏上），周圍留大量黑色 padding |
| Format | PNG，~512×512（@2x），背景透明（會疊在純黑底色上） |

### 為什麼要簡化版

主畫面 launch 起來是黑底 + 動態 accent，**launch screen 不能跟它太相似**（不然看不出 launch 結束）也**不能太喧嘩**（不是廣告）。簡化版線稿 / monochrome icon 居中是 iOS 慣例（看 Telegram, Things 3, Linear 等都這風格）。

### Deliverable

- **launch_screen_icon.png**（512×512，透明背景，monochrome / line art 風）
- 1 個就夠（不需要 variant）

---

## 5. 整體交付清單

| 檔案 | 規格 | 數量 |
|---|---|---|
| `app_icon_variant_a.png` | 1024×1024，PNG，不透明 | 1 |
| `app_icon_variant_b.png` | 同上 | 1 |
| `app_icon_variant_c.png`（可選） | 同上 | 0-1 |
| `launch_screen_icon.png` | 512×512，PNG，透明背景 | 1 |
| `notes.md`（可選） | 設計決策說明 / 用色 / future variant | 0-1 |

打包傳 zip 即可，跟之前同 channel。

---

## 6. 預算 / 時程

[ 待填 ]

| 項 | 期望 |
|---|---|
| 出第一輪稿 | _____ |
| 修改回合 | _____ 輪 |
| 預算 | NT$ _____ |

---

## Appendix：給設計師的「快速理解」

1. **下載你之前做的 iOS app `ios/kc_smart_lamp/` 直接 build 跑看視覺**（user 已測過 OK）
2. **看 GitHub 大頭貼**：[ URL ]，這是主要 anchor
3. **想兩個 variant**：暖色 / 冷色 各一，黑底發光圓點是核心元素
4. **launch screen 別過度設計**：就 launch_screen_icon.png 一張，黑底 / 線稿 / 居中
