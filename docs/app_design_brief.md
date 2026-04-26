# kc_smart_lamp iOS App — Design Brief

**Status**: Draft（尚未發包給設計師）
**Date**: 2026-04-26
**For**: 接案設計師 / 工作室 / 未來自己重看

> **English summary:** Design brief for the kc_smart_lamp iOS companion app, addressed to a freelance designer (or the future self trying to remember the original direction). Covers product positioning, target users, key use scenarios, visual style, layout, and just enough technical context for design decisions. Sections 1-5 are required reading; 6-10 are reference depth.

> **設計師閱讀順序建議**：第 1-5 節先讀（產品 / user / 場景 / 風格），第 6-9 節是 functional / layout / 細節（在實際下手前再深入），第 10 節是技術背景（不必讀懂，僅供 reference）。

---

## 1. Product (1 句話)

一個 iOS app，用 Bluetooth 控制桌上的自製智能燈泡 — 選色、調亮度、開關、切 preset。

## 2. Why this exists

市售 BLE 智能燈泡的 app 都有共通問題：(a) 必須註冊雲端帳號、(b) 廣告太多、(c) UI 過於複雜、(d) 廠商更新後變更 UX。本專案是**自己有控制權**的替代品。iOS app 是**手機 client**，跟桌機端 Python CLI / Web UI 平級。

## 3. Target user

- **主要**：Owner 自用（一個人、一顆 lamp、一支手機）
- **次要**：朋友來家裡看到，解鎖手機能優雅秀一下
- **不是**：陌生 user、商業用戶、多裝置管理者

## 4. Primary use cases（按頻率排序）

| 優先 | 場景 | 互動需求 |
|---|---|---|
| 1（最高頻）| **快速關燈 / 切到勿擾色** | **不打開 app**，從鎖屏 widget 或控制中心點 1 下 |
| 2 | 白天工作切「Focus」勿擾紅色 | 開 app → 點 preset chip 一鍵 |
| 3 | 晚上小夜燈調暖色 | 開 app → 大色盤拖到暖色區 → 拖亮度 → Apply |
| 4 | 出門前快速 Off | 鎖屏 widget Off 鈕 |

**設計重點**：頻率最高的場景**根本不會打開 app**。Widget / Control Center / Siri 比 app 主畫面更重要。app 主畫面服務的是「想精細調色」的場景。

## 5. Style direction

### 5.1 Primary mood: Tesla App 工業感

**具體要素**：

- 黑底為主，**深色 only**（不做 light mode）
- **大量半透明 frosted glass 卡片**，layered，有空間感
- 工業冷感 + 微科技感
- 動畫**多但 smooth**，spring damping、subtle scale / fade / slide — **不要 bouncy 卡通感**
- **大圓角**：卡片 24-28 px、按鈕 16-20 px、chip 12-16 px

### 5.2 Borrowed from Apple Home（哲學層）

- **單頁完成主要操作**，不要分頁亂跳
- **磁磚 / 卡片 grid** 而不是 list
- **每個元件清楚自己的職責**（一個顏色就一個顏色，不要混合多功能）

### 5.3 References

| 學什麼 | 不學什麼 |
|---|---|
| ✅ Tesla App — mood、玻璃感、動畫節奏 | ❌ Hue / Yeelight — 功能太多、視覺太花 |
| ✅ Apple Home — 簡潔、單頁、卡片佈局 | ❌ 卡通風 / 圓臉 emoji 大量使用 |
| ✅ Linear — 高密度但呼吸感 | ❌ Material Design 重陰影 |
| ✅ Things 3 — 強調色節制 | ❌ 多分頁 tab bar 切來切去 |

### 5.4 Color philosophy

- **背景**：純黑或近黑（#000 或 #0A0A0A）
- **卡片**：半透明白疊在背景上（白 5-10% opacity + backdrop blur）
- **強調色**：**動態 = 當前 lamp 的顏色**。Lamp 紅 → app 強調色紅；Lamp 暖白 → app 強調色暖白。**這個是視覺核心**：app 跟 lamp 視覺同步。
- **文字**：白為主（#FFF / #DDD），次要文字用半透明白（#FFF 60%）

## 6. Functional scope

### 6.1 Must-have (v1)

| 元件 | 說明 |
|---|---|
| 連線狀態 | scanning / connected / failed 三態，視覺化清楚 |
| 大色盤（hero element） | HSV 色輪 或 Apple 系統 ColorPicker，**主視覺、佔螢幕中央** |
| 亮度滑桿 | 0-100% 水平滑桿，數字百分比顯示 |
| Power 開關 | toggle，視覺上連動主色（開 → 主色亮起，關 → 淡灰） |
| Apply 按鈕 | 主 CTA，按下送出 BLE write、回 feedback「Applied」 |
| 3 個 preset chip | Focus（紅）/ Warm（暖白 30%）/ Off — tap 直接套用 + 寫進 lamp（不再按 Apply） |

### 6.2 Nice-to-have (v1.x)

| 元件 | 說明 |
|---|---|
| Lock Screen widget | 顯示開關 + 主色（無需打開 app） |
| Control Center toggle | 一鍵開關 |
| Siri Shortcut | 「Hey Siri, lamp red」/「lamp off」 |
| App icon | 黑底 + 發光圓 LED + 微 gradient |
| Haptic feedback | preset tap / connection 連上瞬間 |

### 6.3 Won't-have（明確 out of scope）

| 元件 | 為什麼不做 |
|---|---|
| 多 lamp 管理 | v1 只有一顆 |
| 帳號 / 雲端 / 同步 | 純本地 BLE，無雲端 |
| 排程 / scene engine / effect 編輯器 | 依 [ADR 0003 thin-client architecture](decisions/0003-thin-client-architecture.md)，這些在 Mac 端跑 |
| Pairing / 配對 | v1 走 Just Works，無需 PIN |

## 7. Layout / Interaction

### 7.1 主畫面（single screen，不分頁）

```
┌────────────────────────────────┐
│  ●  connected · kc_smart_lamp  │  ← 連線狀態 dot + 名稱
│                                 │
│         ╱─────────╲             │
│        │           │            │
│        │  COLOUR   │            │  ← Hero: 大色盤
│        │   WHEEL   │            │     佔 50-60% 高度
│         ╲─────────╱             │     當前色 dominant
│                                 │
│  Brightness                     │
│  ●─────────────●─────  60%      │  ← 滑桿 + 數字
│                                 │
│   ┌──────┐ ┌──────┐ ┌──────┐    │
│   │Focus │ │ Warm │ │ Off  │    │  ← Preset chips
│   └──────┘ └──────┘ └──────┘    │
│                                 │
│  ┌───────────────────────────┐  │
│  │         A P P L Y          │  │  ← Primary CTA
│  └───────────────────────────┘  │
│                                 │
│  ⚪︎ Power on                    │  ← Toggle (低調，因為 Apply 已涵蓋)
└────────────────────────────────┘
```

> 設計師可以重新編排，這只是 placement 草圖。

### 7.2 Connection state 視覺

| 狀態 | 視覺 |
|---|---|
| Scanning | dot 灰色閃爍 + 「scanning...」 |
| Connected | dot 綠 + lamp 名稱 + 微震動 + 從上方滑入 |
| Failed | dot 紅 + 「Tap to retry」 + tap 後重新 scan |
| Disconnected mid-session | dot 變橘 + 自動 retry，3 次失敗才顯示 fail |

### 7.3 Widget（v1.x）

```
鎖屏小 widget（systemSmall）：

┌──────────┐
│   ●      │  ← 主色光點
│  ON      │  ← 狀態
│  Smart   │
│  Lamp    │
└──────────┘

點擊 → toggle on/off
長按 → 跳到 app 主畫面
```

## 8. Animation / Micro-interactions

期望「動畫多但 smooth」。具體：

| 觸發 | 動畫 |
|---|---|
| App 開啟 | 卡片從下往上 slide-in（spring response 0.4, damping 0.7） |
| Connection 連上 | dot 從灰 fade 到綠 + 微 scale 1.0 → 1.1 → 1.0（spring） |
| Color wheel 拖動 | 整個 backdrop 輕微著色（玻璃感受拖到的色影響）— **這是 Tesla 風的關鍵** |
| Preset tap | chip 微 press（scale 0.95）+ 0.3s 後玻璃漣漪擴散到全螢幕，動畫結束時主色變到對應色 |
| Apply 按下 | 按鈕 scale 0.98 → 1.0 + "Applied" 文字浮現 → 2s 後淡出 |
| Brightness 拖動 | 拖動時整個 UI backdrop 跟著明暗變化（讓 user 感覺「真的在調亮度」） |
| Power toggle off | 整個 UI 主色淡出到灰，玻璃卡片變更暗 |
| Power toggle on | 整個 UI 主色從灰恢復到當前色 |

**節奏原則**：所有動畫 < 0.5s，spring damping 0.6-0.8。**不要慢動畫**（會讓 user 等）；**不要 bouncy**（會讓人覺得幼稚）。

## 9. Constraints

| 項 | 值 |
|---|---|
| iOS 版本 | iOS 17+（用最新 SwiftUI / 17 widget API） |
| Devices | iPhone only（不做 iPad 版） |
| Theme | Dark mode only（不做 light mode） |
| 方向 | 直式 only |
| 無障礙 | VoiceOver 基本支援、Dynamic Type 支援（不為了視覺犧牲） |
| 字型 | SF Pro 系統字（不另外買 font） |
| 配色 | 黑 / 白 / 動態主色（從 lamp 當前色取） |

## 10. 給設計師的技術背景（非必讀）

設計師**不需要懂 BLE**。但理解這些對「動畫節奏」設計有幫助：

- App 透過 BLE 對 lamp 寫 5 bytes：power(1B) + R(1B) + G(1B) + B(1B) + brightness(1B)
- 一次 BLE write 延遲 ~30-50 ms（人感覺不到）
- 連線：scan ~2-5 秒、connect ~1-2 秒、之後 keep-alive
- 連線中斷會自動 retry
- 一顆 lamp 同時只能被一個 client 連 → 如果 user 在 Mac 開了 web UI，iPhone 就連不上（這是 BLE peripheral 的天然限制，不是 bug）

技術 spec 完整版見 [GATT spec](gatt_spec.md)。

## 11. Brand / Visual hand-off

| 項 | 提案 |
|---|---|
| App 名稱 | "Smart Lamp" 或 "kc_smart_lamp" |
| 主視覺 icon | 黑底 + 一顆發光圓 LED + 微 radial gradient |
| Splash screen | 不要（iOS 17 不鼓勵 splash screen） |
| 字型 hierarchy | SF Pro Display Large Title + SF Pro Body + SF Pro Mono（顯示 hex code 時） |
| 圓角系統 | xs=8 / sm=12 / md=16 / lg=24 / xl=32 |
| Spacing 系統 | 4 / 8 / 16 / 24 / 32 / 48 |

## 12. 預算 / 時程

[ 待填 ]

| 項 | 期望 |
|---|---|
| Figma 設計時程 | _____ |
| 修改回合 | _____ 輪 |
| 預算 | _____ |
| Deliverable | Figma file（含 design system / 主畫面 / widget mockup / animation spec） |

---

## Appendix A：給設計師的「我喜歡 / 討厭」截圖區

[ 待填，建議放 Tesla App / Apple Home 各 5 張，加 1 句 evaluation。設計師看截圖比看文字精準 10 倍。]

## Appendix B：iOS app 在 repo 的位置

- Code 在 `ios/` 目錄（Swift + SwiftUI + CoreBluetooth）
- 跟 firmware / host / hardware 平級的 deliverable line
- iOS app 跟 Python host client **共享 GATT spec**（[gatt_spec.md](gatt_spec.md)），實作各自獨立
