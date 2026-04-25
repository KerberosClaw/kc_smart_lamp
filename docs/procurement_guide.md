# 採購指南 / Shopping Script

> **English TL;DR**: A read-aloud shopping script for sourcing the no-solder bring-up parts (ESP32-C3 SuperMini pre-soldered, WS2812B 8-LED Ring with pre-soldered leads, breadboard, jumper wires) at a Taiwanese electronics shop. Locale-bound to Mandarin storefronts. International readers can use the parts table + decision rationale, but the speech sections won't apply.

進電子材料行時可直接「照唸」。本文件目標：讓**沒硬體經驗**的 owner（或未來 clone repo 的人）也能順利把所有元件買齊。

設計原則見 [ADR 0001](decisions/0001-led-form-factor.md)（為何選 8 LED Ring）+ [ADR 0002](decisions/0002-no-solder-bring-up.md)（為何完全不焊接）。

---

## 採購清單

| # | 物件 | 規格 / 必須條件 | 約價 NT$ |
|---|---|---|---|
| 1 | ESP32-C3 SuperMini | **排針已焊好** | 150–220 |
| 2 | WS2812B 8 LED Ring | **接線已預焊**（杜邦線或 JST connector） | 80–150 |
| 3 | 麵包板 | 400 孔小型 | 30–50 |
| 4 | 杜邦線 | 公對母 + 母對母，各一包 | 50–80 |
| 5 | USB-C 線（資料 + 電源） | 家裡有就免買 | 0–80 |

**估算總計**：NT$ 310–580

---

## Step 1 — 進店前先打電話

```
您好，我想做一個 ESP32-C3 SuperMini + WS2812B 桌燈，完全不焊接。
請問兩個：

1. ESP32-C3 SuperMini，「排針已焊好」的版本有沒有貨？
   沒有的話可不可以代焊？

2. WS2812B「8 LED Ring」，接線已經預焊好的版本有沒有貨？

都有的話我直接過去。
```

打通了再過去。沒打通就到現場直接問同一段話。

---

## Step 2 — 進店逐項確認（照唸版）

### 2.1 ESP32-C3 SuperMini

```
我要 ESP32-C3 SuperMini，排針已焊好的版本。

沒有的話可不可以麻煩代焊？

或者，有沒有別款 ESP32 開發板，是出廠就焊好排針的？
我新手不會焊。
```

**店員可能推薦的替代品**：

- **ESP32 NodeMCU DevKit V1** — 永遠出廠焊好，但只有 BLE 4.2（不是 5.0）
- **ESP32-S3 DevKitC-1** — 永遠焊好、BLE 5.0、體積較大、價格較高

對本專案而言，BLE 4.2 / 5.0 都行 — GATT server 寫法相同。**任何 ESP32 系列 + BLE + 已焊排針**都可。買到後在 README 記下實際型號。

### 2.2 WS2812B 8 LED Ring

```
我要 WS2812B「8 LED Ring」，
接線是預焊杜邦線或 JST connector 的版本。
```

**沒貨時備案順序**（仍要求預焊接線）：

1. **Jewel 7**（1 中心 + 6 周圍）— 形狀適合「總狀態 + 分項狀態」
2. **Stick 8**（直線排列 8 顆）— 直線版替代
3. **WS2812B 燈條 1m 60-LED**（最後手段）— 前 5 顆用，後面 firmware 設黑

**不要**選 16 LED Ring 以上 — 對 5 顆獨立可控的需求過大（浪費 11 顆以上）。

### 2.3 麵包板

```
400 孔小型麵包板，一塊。
```

任何品牌都行。

### 2.4 杜邦線

```
杜邦線，公對母一包 + 母對母一包，10cm 或 20cm 都可以。
```

不要只買公對公 — 接不到 ESP32 的母排針，也接不到 Ring 的母接頭。

### 2.5 USB-C 線（家裡沒有再買）

```
USB-C 線一條，要能傳資料的，不是只能充電的那種。
```

少數 USB-C 線只接電不接資料，會無法燒錄 firmware。買時要確認。

### 2.6 供電方案確認

```
ESP32-C3 SuperMini 接 8 顆 WS2812B，全部從 ESP32 的 5V pin 供電，
需不需要另外買外接電源？
```

理論計算：8 顆 LED 滿白 ~480mA，USB 5V 直供應該夠。但讓店員確認他賣的 ESP32 SuperMini 5V pin 規格。若店員說要外接，加買 5V/1A USB 電源 + USB-A 母座轉杜邦線。

---

## Step 3 — 結帳前最後檢查

- [ ] **ESP32 排針已焊** — 現場插一下杜邦線確認接得上
- [ ] **WS2812B Ring 接線已焊** — 看一下三條線（5V / GND / DIN）露出
- [ ] 麵包板 400 孔
- [ ] 杜邦線：公對母 + 母對母 各一包
- [ ] 供電方案已確認（USB 5V 直供 OR 外接電源）
- [ ] USB-C 線可傳資料（非純充電線）

---

## Step 4 — 採購後回到專案

完成採購後請記錄：

1. 在 `README_zh.md` / `README.md` 補上實際採購的 SKU + 日期 + 總價
2. 把 [ADR 0001](decisions/0001-led-form-factor.md) / [ADR 0002](decisions/0002-no-solder-bring-up.md) 的 `Status` 從 `Accepted` 改成 `Procured YYYY-MM-DD with <實際 SKU>`
3. （選配）拍照存 `docs/photos/procurement_YYYY-MM-DD.jpg`

---

## 為什麼這麼囉嗦

未來的 you（或其他人）可能：

- 距離這次採購已過半年，忘記為什麼選 8 LED Ring 而不是 16
- 在不同店、不同國家採購，店員語言/品項不同
- 第一次玩硬體，需要店員溝通範本

把規格、備案、店員問答、checklist 一次寫齊，**未來就不用重新推導**。
