# 採購指南 / Shopping Script

> **English summary:** A shopping script for the kc_smart_lamp hardware bill of materials, written so an owner without prior electronics experience (or a future cloner of this repo) can walk into a Taiwanese electronics shop and read the page out loud. First procurement run completed 2026-04-26; document kept for restocks and re-buys. Design rationale: ADR 0001 (LED form factor) + ADR 0002 (no soldering).

進電子材料行時可直接「照唸」。本文件目標：讓**沒硬體經驗**的 owner（或未來 clone repo 的人）也能順利把所有元件買齊。

設計原則見 [ADR 0001](decisions/0001-led-form-factor.md)（為何選 8 LED Ring）+ [ADR 0002](decisions/0002-no-solder-bring-up.md)（為何完全不焊接）。

> **本文 scope**：可重複使用的「電子材料行採購腳本」。**首次採購已於 2026-04-26 完成**，買到的實際品項 / 價格 / 店家見 [`dev_setup.md` → Hardware](dev_setup.md#hardware)。本文留作：(a) 未來補料 / 替換用、(b) 其他 cloner 自己買時參考。

---

## 採購清單

| # | 物件 | 規格 / 必須條件 |
|---|---|---|
| 1 | **ESP32-S3-WROOM-1 N16R8 開發板** | **排針已焊好**、Native USB-C、PCB 天線 |
| 2 | WS2812B 8 LED Ring | **接線已預焊**（杜邦線或 JST connector） |
| 3 | 麵包板 | 400 孔小型 |
| 4 | 杜邦線 | 公對母 + 母對母，各一包 |
| 5 | USB-C 線（資料 + 電源） | 家裡有就免買 |

> **備註：實體材料行 vs 網購的權衡** — 同型號 chip 線上通路通常較便宜，但**第一次跑硬體建議去實體店**，理由見下節「為什麼要到現場看（不能直接網購）」。
>
> **本專案的實際採購 (2026-04-26)**：在金華電子（光華商場）買到 ESP32-S3-WROOM-1 N16R8 焊好版 + 杜邦線兩包，WS2812B Ring 改走蝦皮（要「預焊線版本」+ 單純電子材料行較難確認版本），詳見 [dev_setup.md](dev_setup.md)。

---

## 為什麼要到現場看（不能直接網購）

2026-04-26 跟今華電子（台中）電話確認時，老闆的建議：**「ESP32 型號很多，建議到現場看」**。實際理由：

- **型號 / 板廠變體多**：ESP32-S3-WROOM-1 光是「N4 / N8 / N16 + R2 / R8」flash + PSRAM 組合就 6 種以上，網購圖片不一定反映實物
- **排針有沒有焊**：網購圖示 vs 實物可能不一致，到現場看才確認
- **代焊服務通常沒有**（今華電子 2026-04-26 確認沒有，金華電子也未提供）→ 排針沒焊好就要自己焊或換店
- **接線品質**：WS2812B Ring 預焊接線品質差很多，現場捏一下就知道
- **問題即時解**：現場直接問店員相容性、供電方案，比 Q&A 來回快

**結論**：第一次跑硬體去實體店，貴一點但少踩坑。**網購留給「我已經知道要買哪顆 SKU、補料」的階段** — 例如本專案 WS2812B Ring 因實體店家難確認預焊版本，後來改走蝦皮指名「預焊線」。

---

## Step 1 — 進店前先打電話（選配）

打電話只是省「白跑」風險。要跑多家店時可跳過，直接去現場問。

```
您好，我想做一個 ESP32-S3 + WS2812B 桌燈，完全不焊接。
請問兩個：

1. ESP32-S3-WROOM-1 N16R8 開發板，「排針已焊好」的版本有沒有貨？
   或者其他焊好排針的 ESP32-S3 / S3-DevKitC-1 也行。

2. WS2812B「8 LED Ring」，接線已經預焊好的版本有沒有貨？

都有的話我直接過去。
```

**已知資訊**：
- 今華電子（台中，2026-04-26 電話確認）— 沒有代焊服務，老闆建議到現場看型號
- 金華電子（光華商場，2026-04-26 採購當日）— 有 ESP32-S3-WROOM-1 N16R8 焊好排針版，沒代焊服務
- WS2812B Ring 預焊版實體店家難確認 → 走蝦皮指名「預焊線」較穩

---

## Step 2 — 進店逐項確認（照唸版）

### 2.1 ESP32-S3 開發板

```
我要 ESP32-S3-WROOM-1 N16R8 開發板，排針已焊好的版本，
要 Native USB-C（不是 micro USB）。

沒有的話，有沒有別款 ESP32-S3 開發板，是出廠就焊好排針 + USB-C 的？
我新手不會焊，也不需要代焊服務（已知多數材料行沒這服務）。
```

**規格優先順序**：

1. **必要**：ESP32-S3 系列（不要 ESP32 classic、不要 C3，目標板能跑 BLE 5.0 + USB-Serial/JTAG）
2. **必要**：排針已焊好
3. **必要**：Native USB-C 接口（不是要轉接的 micro USB）
4. **強烈偏好**：WROOM-1 N16R8（16MB Flash + 8MB PSRAM，未來 OTA / 大資料量留空間）
5. **可接受替代**：WROOM-1 N8R2 / N4R2（Flash 容量小一些，目前 1 MB app 也夠用）

**店員可能推薦的替代品**：

- **ESP32-S3-DevKitC-1** 官方版 — 永遠焊好，貴一點但 reference 設計穩
- **ESP32-S3 SuperMini / Zero** — 體積極小，BLE 5.0、USB-C，但排針焊好版本不一定有
- **ESP32 NodeMCU DevKit V1** — 永遠焊好，但只有 BLE 4.2 + 沒 native USB（不推，會多踩 UART bridge 的坑）
- **ESP32-S2** — 沒 BLE，**不可用**

對本專案而言，**任何 ESP32-S3 + 已焊排針 + Native USB-C** 都可。買到後在 [dev_setup.md](dev_setup.md) 記下實際型號 + 該型號的 GPIO 對板載 LED 的接法。

### 2.2 WS2812B 8 LED Ring

```
我要 WS2812B「8 LED Ring」，
接線是預焊杜邦線或 JST connector 的版本。
```

**沒貨時備案順序**（仍要求預焊接線）：

1. **Jewel 7**（1 中心 + 6 周圍）— 形狀適合「總狀態 + 分項狀態」
2. **Stick 8**（直線排列 8 顆）— 直線版替代
3. **WS2812B 燈條 1m 60-LED**（最後手段）— 前 8 顆用，後面 firmware 設黑

**不要**選 16 LED Ring 以上 — 對 8 顆獨立可控的需求過大（浪費 8 顆以上）。

**實際採購策略**：本專案 WS2812B Ring 改走蝦皮搜尋 `WS2812B 8 LED Ring 預焊線` / `Neopixel Ring 8 焊接好`，因實體店家不容易確認「真的預焊好」vs「焊盤裸露要自己焊」。網購圖片 + 商品描述比較好比對。

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
ESP32-S3 接 8 顆 WS2812B，全部從 ESP32 的 5V pin 供電，
需不需要另外買外接電源？
```

理論計算：8 顆 LED 滿白 ~480mA，USB 5V 直供應該夠（USB 標準 ≥ 500mA）。**8 顆以下 OK，超過 16 顆強烈建議外接電源**（5V/2A USB 變壓器 + USB-A 母座轉杜邦線）。

---

## Step 3 — 結帳前最後檢查

- [ ] **ESP32 排針已焊** — 現場插一下杜邦線確認接得上
- [ ] **ESP32 是 Native USB-C**（不是 micro USB 或要轉接）
- [ ] **ESP32 是 S3 系列**（看晶片或盒裝標示，不是 classic / C3 / S2）
- [ ] **WS2812B Ring 接線已焊**（如有當場買）— 看一下三條線（5V / GND / DIN）露出
- [ ] 麵包板 400 孔
- [ ] 杜邦線：公對母 + 母對母 各一包
- [ ] 供電方案已確認（USB 5V 直供 OR 外接電源）
- [ ] USB-C 線可傳資料（非純充電線）

---

## Step 4 — 採購後回到專案

完成採購後請記錄：

1. 在 [dev_setup.md → Hardware](dev_setup.md#hardware) 補上實際採購的 SKU + 日期 + 價格 + 店家
2. 把 [ADR 0001](decisions/0001-led-form-factor.md) / [ADR 0002](decisions/0002-no-solder-bring-up.md) 的 `Status` 從 `Accepted` 改成 `Procured YYYY-MM-DD with <實際 SKU>`
3. （選配）拍照存 `hardware/photos/procurement_YYYY-MM-DD.jpg`
4. **第一次拿到板子先做 [`dev_setup.md` → M1（hardware power-on）](dev_setup.md#m1-hardware-power-on不接-led-不裝環境也能做)** — 5 分鐘驗證 USB 線 + 板子都活著，再進 M2

---

## 為什麼這麼囉嗦

未來的 you（或其他 cloner）可能：

- 距離這次採購已過半年，忘記為什麼選 8 LED Ring 而不是 16
- 在不同店、不同國家採購，店員語言／品項不同
- 第一次玩硬體，需要店員溝通範本

把規格、備案、店員問答、checklist 一次寫齊，**未來就不用重新推導**。
