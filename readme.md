![OpenWrt logo](https://raw.githubusercontent.com/openwrt/openwrt/refs/heads/main/include/logo.png)

Modern OpenWrt build targeting the msm8916 platform (uz801 and sp970 Chineese 4g Dongles) with full modem and USB gadget support.

## Table of Contents

- [About OpenWrt](#about-openwrt)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Building](#building)
- [Installation](#installation)
  - [Flashing from OEM Firmware](#flashing-from-oem-firmware)
  - [Accessing Boot Modes](#accessing-boot-modes)
- [Troubleshooting](#troubleshooting)
  - [No Network / Modem Stuck at Searching](#no-network--modem-stuck-at-searching)
- [Roadmap](#roadmap)
- [Credits](#credits)

---

## About OpenWrt

OpenWrt Project is a Linux operating system targeting embedded devices. Instead of trying to create a single, static firmware, OpenWrt provides a fully writable filesystem with package management. This frees you from the application selection and configuration provided by the vendor and allows you to customize the device through the use of packages to suit any application.

## Features

### Working Components
- **Modem**: Fully functional with cellular connectivity
  - ModemManager Rx/Tx stats not displayed in LuCI (known issue)
- **WiFi**: Complete wireless support
- **USB Gadget Modes**: NCM, RNDIS, Mass Storage, ACM Shell
  - Configure via [UCI](packages/uci-usb-gadget/readme.md) or LuCI app
- **VPN Ready**: TUN driver and WireGuard pre-installed
- **LED Control**: Managed via `hotplug.d` scripts
  - Note: LEDs are swapped in default kernel DTS
  - WiFi LED: [99-modem-led](packages/ledcontrol/files/99-modem-led)
  - Modem LED: [99-wifi-led](packages/ledcontrol/files/99-wifi-led)

### Storage & Recovery
- **SquashFS Root**: Compressed root filesystem
- **OverlayFS**: ext4 overlay partition for user data
- **Factory Reset**: `firstboot` mechanism enabled

### Additional Packages
- **Tailscale**: LuCI app included in `/root` (manual installation required)
  - Install with: `apk add --allow-untrusted /root/luci-app-tailscale*.apk`
  - Not auto-installed to save space

## Prerequisites

- Docker installed on your system
- Basic knowledge of Linux command line
- For flashing: [edl tool](https://github.com/bkerler/edl)

## Building

1. Enter the build environment:
```shell
cd devenv
docker compose run --rm builder
```

2. Configure and build:
```shell
cp /repo/uz801_diffconfig .config
# cp /repo/sp970_diffconfig .config
echo "# CONFIG_SIGNED_PACKAGES is not set" >> .config  # Optional: disable signature verification
make defconfig
make -j$(nproc)
```

## Installation

### Flashing from OEM Firmware

1. **Install EDL tool**: https://github.com/bkerler/edl
2. **Enter EDL mode**: See [PostmarketOS wiki guide](https://wiki.postmarketos.org/wiki/Zhihe_series_LTE_dongles_(generic-zhihe)#How_to_enter_flash_mode)

3. **Backup original firmware**:
  ```shell
  edl rf backup.bin
  ```

4. **Flash OpenWrt**:
  ```shell
  ./openwrt-msm89xx-msm8916-yiming-uz801v3-flash.sh
  # ./openwrt-msm89xx-msm8916-generic-sp970-flash.sh
  ```
   > The script automatically backs up device-specific partitions, flashes the firmware, and restores critical data.

### Accessing Boot Modes

**UZ801**:
- **Fastboot mode**: Insert device while holding the button
- **EDL mode**: Boot to fastboot first, then execute: `fastboot oem reboot-edl`

**SP970**: 
- The only other mode you can enter is **EDL Mode**. To do so just short usb's `gnd` the data pin closest to it.

## Troubleshooting

### No Network / Modem Stuck at Searching

The modem requires region-specific MCFG configuration files.

#### Extract MCFG from Your Firmware

1. **Dump modem partition**:
   ```
   edl r modem modem.bin
   ```

2. **Mount and navigate**:
   ```
   # Mount modem.bin (it's a standard Linux image)
   cd image/modem_pr/mcfg/configs/mcfg_sw/generic/
   ```

3. **Select your region**:
   - `APAC` - Asia Pacific
   - `CHINA` - China
   - `COMMON` - Generic/fallback
   - `EU` - Europe
   - `NA` - North America
   - `SA` - South America
   - `SEA` - South East Asia

4. **Locate your carrier's MCFG**: Navigate to your telco's folder and find `mcfg_sw.mbn`. If your carrier isn't listed, use a generic configuration from the `common` folder.

#### Apply the Configuration

**Transfer to device** (capitalization matters!):
   ```
   scp -O mcfg_sw.mbn root@192.168.1.1:/lib/firmware/MCFG_SW.MBN
   # ... and reboot the device ...
   ```


## Roadmap

- [ ] Custom package server for msm89xx/msm8916
  - Note: Target-specific modules may require building from source via `make menuconfig`
  - Removed feed: `https://downloads.openwrt.org/snapshots/targets/msm89xx/msm8916/packages/packages.adb`
- [ ] Investigate `lpac` for eSIM support
- [ ] Memory expansion: swap/zram configuration

## Credits

- **[@ghosthgy](https://github.com/ghosthgy/openwrt-msm8916)** - Initial project foundation
- **[@lkiuyu](https://github.com/lkiuyu/immortalwrt)** - MSM8916 support, patches, and OpenStick feeds
- **[@Mio-sha512](https://github.com/Mio-sha512/OpenStick-Builder)** - USB gadget and firmware loader concepts
- **[@AlienWolfX](https://github.com/AlienWolfX/UZ801-USB_MODEM/wiki/Troubleshooting)** - Carrier policy troubleshooting guide
- **[@gw826943555](https://github.com/gw826943555/luci-app-tailscale) & [@asvow](https://github.com/asvow)** - Tailscale LuCI application
- **[@HandsomeMod](https://github.com/HandsomeMod/linux-msm/blob/main/arch/arm64/boot/dts/qcom/msm8916-handsome-openstick-sp970.dts)** - Base for the `sp970` dts.
