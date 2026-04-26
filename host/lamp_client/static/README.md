# kc_smart_lamp Web UI

Vanilla HTML + CSS + JS。沒有 build step、沒有 npm dep、沒有 framework。FastAPI mount `static/` 直接 serve 即可。

視覺方向 1:1 對齊 `ios/` 那組 SwiftUI 實作（Tesla 工業風 + frosted glass + dynamic accent + 黑底 only）。

## 跑起來

### 1. 開發 — 直接開瀏覽器

```bash
open web/index.html       # macOS
# 或
python3 -m http.server 8000 --directory web
```

直接開 file:// 也可以跑（只是 `/api/set_state` 會 404 → 進 demo mode，UI 全程可測）。

### 2. 整合進 FastAPI

把 `web/` 整個 mount 成 static 即可：

```python
from fastapi.staticfiles import StaticFiles
app.mount("/", StaticFiles(directory="web", html=True), name="web")
```

或 copy 到既有的 static 路徑下。

## 檔案

| 檔 | 用途 |
|---|---|
| `index.html` | DOM 結構、無內聯 style |
| `styles.css` | 所有視覺,CSS variables 對應 iOS `LampMetrics` |
| `app.js` | State + render + interactions + fetch `/api/set_state` |

## 對應 iOS

| iOS 檔 | Web 對應 |
|---|---|
| `LampApp.swift` `LampMetrics` | `:root` CSS variables (`--r-card`, `--pad`, `--t-base`...) |
| `LampApp.swift` `accentColor` | `--accent` / `--accent-r/g/b` ,JS 在 `render()` 重寫 |
| `LampScreen.swift` ZStack 三層 (黑底 + radial + dot grid) | `body::before` (radial) + `body::after` (dot grid) |
| `ColorWheelView.swift` | `.wheel` + `wireWheel()` |
| `BrightnessSlider.swift` | `.slider` + `wireBrightness()` |
| `PresetChip.swift` / `PresetRow.swift` | `.chip` + `wirePresets()` ,tap 直接 send |
| `ApplyButton.swift` | `.apply` + `wireApply()` |
| `PowerToggleRow.swift` | `.power-row` + `.toggle-switch` |
| `ConnectionPill.swift` | `.conn-pill` + `data-state` 切換 |

## API contract

對 backend 唯一的依賴:

```
POST /api/set_state
Content-Type: application/json
{
  "power": true|false,
  "r": 0-255,
  "g": 0-255,
  "b": 0-255,
  "brightness": 0-100
}
→ 200 {"ok": true}
```

跟現有 `current_web/index.html` 完全一致。後端不必改。

## RWD

| breakpoint | 行為 |
|---|---|
| `< 980px` (手機 / tablet) | 單欄,主面板 max-width 460px,連線狀態 cards 隱藏 |
| `>= 980px` (桌機) | 雙欄,右側多一個 connection-states showcase 可點切換 demo 各狀態 |

色盤大小用 `min(78vw, 320px)`,小手機螢幕也不會撐爆。

## 動畫節奏

統一用 `cubic-bezier(.3, .7, .4, 1)` (對應 Swift 的 `spring(response: 0.4, dampingFraction: 0.75)`)。
所有 transition < 0.5s,不 bouncy。`prefers-reduced-motion` 會降到 0.01ms。

## 後續延伸 (Claude Code 可接手的點)

1. **狀態持久化**:現在 reload 後 state 重設,可用 `localStorage` 或先打 `GET /api/state`
2. **真實連線狀態**:目前 connection pill 是純 UI demo,可接 WebSocket / SSE 把 backend 的 BLE 連線狀態推上來
3. **i18n**:現在中英混合,要全英 / 全中可抽 string table
4. **Keyboard accessibility**:wheel + slider 已有 `tabindex`,但還沒接 arrow key handler,可補上
5. **Build pipeline (optional)**:若要壓 css/js,加 `esbuild` 或 `vite` 一行搞定,但不是必要
