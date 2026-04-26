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
4. S3C2451 iROM boot layout 跟主流不同（**非 bug，是 mask ROM 寫死的 boot 規範，物理上無法更新**）— bootloader 必須出現在 SD 卡末端特定 sector，無法直接 dd 一般 Pi-style raw image。`sd-fuse_nanopi/fusing.sh` 知道這些 offset 用 dd 寫到對位置；做出來的 image 再 dd 到 SD 才能正確 boot。FriendlyARM 後續產品（NanoPi M1 / NEO / Air...）換 SoC 後已無此 layout 怪癖
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

1. 封裝形式：3D 列印外殼？開模？還是用現成壓克力盒？
2. 是否要加實體按鈕（GPIO input）做 fallback 控制？

## 採購清單（NanoPi 路線估算）

| 項目 | 規格 |
|---|---|
| WS2812B LED strip | 1m 60 LED 5V（用前 5 顆即可） |
| 杜邦線 | 公對公 + 母對公 各一包 |
| USB-A 公頭 → 杜邦線 | 取 5V 給 LED 供電 |
| 1000μF 電解電容 + 470Ω 電阻 | WS2812 防電源浪湧推薦 |
| USB-TTL 線（選配） | UART debug，USB Gadget 卡住的後備 |

SD 卡家裡有，NanoPi 家裡有。

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

## 踩雷紀錄（2026-04-26 首次嘗試 Path B）

實際走 Path B 流程踩到的坑（按順序記，未來重試可避）：

1. **`sd-fuse_nanopi/fusing.sh` 用過時 sfdisk 旗標** — `sfdisk -u S -f --Linux` 在 util-linux 2.32+ 已移除。Debian 13 (Trixie) 跑會 silent fail（fusing.sh 的 `try()` wrapper 沒抓到），結果是「BL/kernel 寫入 OK，但 partition table 沒建」。
   - 修法：`sed -i 's/sfdisk -u S -f --Linux/sfdisk -f/g' fusing.sh`
2. **`mkrootfs.sh` 對 loop device 的 partition naming 有 bug** — script 寫死 `/dev/${DEV_NAME}1` → 對 `/dev/loop0` 變 `/dev/loop01`，但 kernel 實際 enumerate 是 `/dev/loop0p1`（多 `p`）。
   - 修法：跑 mkrootfs.sh 前 `for i in 1 2 3; do ln -sf /dev/loop0p$i /dev/loop0$i; done`
   - 注意：對 `/dev/sda` 沒這問題（partition 是 sda1/sda2/sda3，無 `p`），所以**直接燒實體 SD 比走 image 簡單**
3. **rootfs tarball URL 過期** — `wiki.friendlyarm.com` 重導到 `wiki.friendlyelec.com`（新 domain），且 HTTPS cert 過期。mkrootfs.sh 的 `wget` 無 `--no-check-certificate` 拿到 ~800-byte HTML 錯誤頁，假裝成功但 tar 解開時 `gzip: stdin: not in gzip format` 才爆。
   - 修法：手動 pre-download 到 `prebuilt/`：`wget --no-check-certificate -O prebuilt/nanopi-debian-jessie-rootfs.tgz https://wiki.friendlyelec.com/NanoPi/download/nanopi-debian-jessie-rootfs.tgz`
4. **Image size 必須等於 SD 實際容量** — S3C2451 iROM 從 disk 末端固定 offset 找 BL1。16GB image 燒到 32GB 卡 → bootloader 落在 SD 中間，iROM 看末端是空白 = 不 boot。**不能 dd 一份 image 到比它大的卡**。
   - 解法 A：用 `truncate -s <SD bytes>` 建跟 SD 同大小的 sparse image
   - 解法 B（更簡單）：UTM 連實體 SD，直接 `fusing.sh /dev/sda`，BLOCK_CNT 從 `/sys/block/sda/size` 自動讀
5. **WiFi 預配跳過 USB Gadget RNDIS** — 實作經驗：mount sda2 寫 `/etc/wpa_supplicant/wpa_supplicant.conf` + `/etc/network/interfaces.d/wlan0` 確實 work，NanoPi 開機自動連 WiFi、SSH 起來。M1 沒 HoRNDIS 的限制可繞開
6. **UTM USB passthrough 寫入沒過時靜默失敗** — 但常見原因是 SD 卡本體故障（lock 開關卡死、controller 進 read-only emergency 模式），不一定是 UTM。**每張不熟的 SD 跑 fusing.sh 前先做 persistence test**：
   ```bash
   sudo dd if=/dev/urandom of=/dev/sda bs=512 count=1 seek=100 oflag=direct
   sync
   sudo dd if=/dev/sda bs=512 count=1 skip=100 iflag=direct | od -An -tx1 | head -2
   ```
   讀回零 = 寫入沒持久化 = 換卡或檢查 lock
7. **macOS Sequoia 對 raw block device 寫入有 system integrity 限制** — 即使 `sudo dd` 到 `/dev/rdiskN` 帶 Full Disk Access 都可能 silent-fail 寫不到 partition table 區。**BalenaEtcher**（內建 privileged helper + 適當 entitlement）能繞開
8. **沒 UART console 等於瞎 debug** — boot 失敗只看到「LED 閃幾下→滅」零訊息。USB-TTL 線（FT232 / CP2102 / CH340）接 GPIO header TX/RX/GND 是最重要的嵌入式 debug 工具，下次採購順手帶一條

**老 SD 卡（特別是用過很多年的 FAT32 老卡）容易進 read-only 救命模式**：本次踩到 2 張 16GB 老卡都是這狀況，唯一還能寫的是 32GB 新 SDHC。但 32GB 寫入成功後仍 boot 失敗（無 UART 看不到死在哪），結論：**等 UART 到貨再戰**。

---

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
