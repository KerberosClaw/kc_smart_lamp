# NanoPi 桌燈調研（已棄用，保留作為對照組）

> **English summary:** Early exploration of using a 2015-era NanoPi as the lamp controller. Rejected in favor of ESP32-C3 + BLE GATT due to (1) WS2812B timing requires SPI bit-bang hack on Linux user space, (2) ~30s Linux boot time hurts demo UX, (3) M1 MBP does not support USB Gadget RNDIS, blocking direct host connection. Kept here as a reference for "same requirement, two platform comparisons."

**狀態**：已棄用，最終方案走 ESP32-C3 + BLE GATT（見 [../README_zh.md](../README_zh.md)）。本檔保留作為「同樣需求兩種解法的對照組」+ 平台選型決策過程紀錄。

---

## 背景

家裡有一片 FriendlyARM 初代 NanoPi (2015)，想做成「桌面 IoT 燈」：封裝後 plug-and-play，平常透過 API 控制顏色 / 亮度。純個人 side project，硬體與時間均自負，不抄任何外部專案 code / spec。

## 硬體現況

| 項目 | 規格 |
|---|---|
| SoC | Samsung S3C2451（ARM926EJ @ 400MHz 單核）|
| RAM | 64MB DDR2 |
| 儲存 | MicroSD（卡槽在背面）|
| 無線 | AP6210：WiFi 802.11 b/g/n + BT 4.0（SDIO）|
| 網路 | **無 RJ45**，只 WiFi 或 USB Gadget |
| GPIO | 40-pin（相容 RPi 2 排針，但訊號是 S3C2451 原生命名 GPF1/GPE12…）|
| OS | 預裝 Debian 8 + Linux 4.1，**armel** 架構（不是 armhf）|

## 重要限制（影響開發決策）

1. armel ARMv5 EABI — 很多 modern 套件、Docker、新版 Node.js 不支援
2. 400MHz + 64MB RAM — 不要在板子編譯，一律 cross-compile
3. Debian 8 EOL — APT 來源要改 archive.debian.org
4. S3C2451 iROM bug — SD 卡不能 dd 直接寫 raw image，必須用官方 `sd-fuse_nanopi/fusing.sh`
5. **M1 MBP 不支援 USB Gadget RNDIS**（HoRNDIS 只支援 Intel Mac）→ 第一次 SSH 必須改走 Linux 機器（見 Path A）或 Mac 上開 UTM Linux VM（見 Path B）

## 技術選擇 — 已決議方向

### 通訊：本地網路 REST API（preferred）or BLE peripheral

**Option 1: WiFi + REST API**
- 板子設好家裡 WiFi，跑 Flask / FastAPI on port 8080
- MBP `curl -X POST http://nanopi.local:8080/led -d '{"r":255,"g":0,"b":0}'`
- 痛點：依賴家裡 AP；換場域要重設 WiFi

**Option 2: BLE peripheral（用 AP6210 BT 4.0）**
- bluez 5.23 peripheral mode 跑 GATT server
- 痛點：armel + Debian 8 上 bluez 老版本，peripheral mode 要 hack；Python `dbus-python` / `bluezero` armel 預編譯雷區

→ 個人桌燈場景偏 **Option 1（WiFi REST）**，簡單直球。BLE 是備案。

### LED 驅動：SPI MOSI bit-bang 模擬 WS2812B 時序

- WS2812B 規範 800kHz ±150ns，Linux GPIO sysfs 抖動爆炸絕對不夠
- **解法**：SPI clock 設 ~3.2MHz，每個 WS2812 bit 用 4 個 SPI bit 編碼（`1100`=高脈衝/`1000`=低脈衝），由 SPI **硬體**輸出 → bypass scheduler → 穩
- 5 顆 LED 場景：USB 5V 直供（總電流 ~300mA），NanoPi USB port 撐得住
- ⚠️ **NanoPi 是 armel + Linux 4.1，現成 ws2812 library 找不到 armel build**，要自己寫 SPI bit-bang code（Python `spidev` lib 應該有 armel 版）

## Open Questions

1. WiFi 還是 BLE 為主？（建議 WiFi REST，先簡單）
2. 第一次 SSH 必須用 PC（M1 MBP RNDIS 不支援）— 流程怎麼定？SSH 進去設 WiFi 後就能切回 MBP 走 WiFi
3. 封裝形式：3D 列印外殼？開模？還是用現成壓克力盒？
4. LED 顆數：5 顆夠展示嗎？或拉到 30 顆做漸變效果？
5. 是否要加實體按鈕（GPIO input）做 fallback 控制？

## 採購清單（NanoPi 路線估算）

| 項目 | 規格 | 約價 NT$ |
|---|---|---|
| WS2812B LED strip | 1m 60 LED 5V（用前 5 顆即可） | 150-200 |
| 杜邦線 | 公對公 + 母對公 各一包 | 50-80 |
| USB-A 公頭 → 杜邦線 | 取 5V 給 LED 供電 | 30 |
| 1000μF 電解電容 + 470Ω 電阻 | WS2812 防電源浪湧推薦 | 30 |
| USB-TTL 線（選配） | UART debug，USB Gadget 卡住的後備 | 100 |

**總計**：約 NT$ 360-440。SD 卡家裡有，NanoPi 家裡有。

## 開發流程 — Path A：PC（Linux 原生）直接燒

```bash
# 1. PC 上 clone 燒卡腳本
git clone https://github.com/friendlyarm/sd-fuse_nanopi.git
cd sd-fuse_nanopi

# 2. 找 SD 卡裝置號（千萬別寫錯）
lsblk

# 3. 燒
sudo ./fusing.sh /dev/sdX

# 4. 拔卡塞 NanoPi，MicroUSB 接 PC（USB Gadget RNDIS 起 link），等 1-2min
ssh root@<NANOPI_USB_GADGET_IP>   # 密碼 fa（FriendlyARM wiki 公開預設）

# 5. 設 WiFi 連家裡 AP
# /etc/network/interfaces.d/wlan0:
#   auto wlan0
#   iface wlan0 inet dhcp
#       wpa-ssid YOUR_SSID
#       wpa-psk YOUR_PASSWORD

# 6. 之後可從 MBP 走 WiFi SSH（板子上 hostname 設 nanopi-lamp）
```

## 開發流程 — Path B：Mac + UTM Linux VM

針對 M-series Mac 沒 PC 可用的情境。M1 沒 HoRNDIS（Intel only）+ macOS 缺 ext4 / `losetup` / GNU coreutils，無法原生跑 `fusing.sh`。解法：UTM 內跑 Linux VM，把 SD 卡 USB 直通給 VM，VM 內燒卡 + **預配 WiFi**（一次解兩個問題 — 燒卡 + 跳過 USB Gadget RNDIS）。

**為什麼不用 OrbStack**：OrbStack 走 Apple Virtualization.framework，**不支援 raw USB 直通**（看不到 `/dev/disk*`）。UTM 走 QEMU，明確支援 USB passthrough。

### 步驟

```bash
# 1. Mac 裝 UTM
brew install --cask utm

# 2. UTM 建一個 Debian arm64 VM（debian.org 抓 arm64 netinst.iso）
#    Memory 2GB / Storage 20GB / 安裝勾 SSH server
#    安裝完開機登入 VM

# 3. SD 卡插 Mac → UTM 視窗 USB 選單 → "Connect to VM"
#    VM 內驗證裝置號（⚠️ 寫錯目標會洗掉 VM 系統碟）
lsblk          # SD 卡通常是 /dev/sda 或 /dev/sdb

# 4. VM 內燒卡（與 Path A 相同）
sudo apt install git
git clone https://github.com/friendlyarm/sd-fuse_nanopi.git
cd sd-fuse_nanopi
sudo ./fusing.sh /dev/sdX

# 5. 燒完不要拔，直接 mount rootfs 預配 WiFi
sudo mkdir -p /mnt/nanopi
sudo mount /dev/sdX2 /mnt/nanopi      # rootfs 通常在第二個 partition

sudo tee /mnt/nanopi/etc/wpa_supplicant/wpa_supplicant.conf > /dev/null <<'EOF'
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="YOUR_SSID"
    psk="YOUR_PASSWORD"
    key_mgmt=WPA-PSK
}
EOF

sudo tee /mnt/nanopi/etc/network/interfaces.d/wlan0 > /dev/null <<'EOF'
auto wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF

sudo umount /mnt/nanopi
sudo eject /dev/sdX

# 6. UTM 把 SD 卡 disconnect → 從 Mac 拔出 → 插 NanoPi → 通電開機
#    等 1-2 分鐘 boot 完，自動連 WiFi

# 7. 從 Mac SSH（不需要 USB Gadget）
ssh root@nanopi.local        # 密碼 fa（FriendlyARM 預設）
# 不通的話：
arp -a | grep -i nanopi      # 從 ARP 表找 IP
ssh root@<找到的 IP>
```

### Troubleshooting

| 症狀 | 解法 |
|---|---|
| `fusing.sh` device busy | SD 卡 partition 自動掛載了，先 `sudo umount /dev/sdX*` |
| VM 看不到 SD 卡 | UTM 設定 → USB controller 改 "USB 3.0 (XHCI)"（不是 USB 2.0） |
| `nanopi.local` 解析不到 | mDNS 沒上來，改用 `arp -a` 或路由器 DHCP 列表找 IP |
| WiFi 連不上 | SSID/PSK 有特殊字元，改用 `wpa_passphrase YOUR_SSID YOUR_PASSWORD` 產生 hash 取代明文 PSK |

## 關鍵 Repo

- 燒卡：https://github.com/friendlyarm/sd-fuse_nanopi
- U-Boot：https://github.com/friendlyarm/uboot_nanopi（branch `nanopi`）
- Kernel：https://github.com/friendlyarm/linux-4.x.y（branch `nanopi-v4.1.y`）
- Rootfs：https://github.com/friendlyarm/rootfs_nanopi
- Wiki：https://wiki.friendlyelec.com/wiki/index.php/NanoPi

**下一步候選**（MBP 新 session 接續時再決）：
- 採購 LED + 杜邦線
- PC 或 Mac VM 燒 SD 卡 + SSH dry run（見 Path A / B）
- 寫 SPI bit-bang prototype（先讓 5 顆 LED 亮一個顏色）
- 開 `kc_nanopi_lamp` repo 正式啟動
