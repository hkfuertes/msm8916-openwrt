![OpenWrt logo](https://raw.githubusercontent.com/openwrt/openwrt/refs/heads/main/include/logo.png)

Modern OpenWrt build targeting the UZ801v3 LTE dongle with full modem and USB gadget support.

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
```
cd devenv
docker compose run --rm builder
```

2. Configure and build:
```
cp /repo/diffconfig .config
echo "# CONFIG_SIGNED_PACKAGES is not set" >> .config  # Optional: disable signature verification
make defconfig
make -j$(nproc)
```

## Installation

### Flashing from OEM Firmware

### Future:
- Recover `msm-firmware-dumper`.
- Investigate `lpac` and eSIM.
- Investigate `SWAP`, `ZRAM`.
- Custom package server for msm89xx/msm8916
  - Any target specific module not present might require to be built from sources. This repo can be used to do that, run `make menuconfig` before `make -j$(nproc)` and select it from the menu.
  - Feed:  `https://downloads.openwrt.org/snapshots/targets/msm89xx/msm8916/packages/packages.adb` has been removed from distfeeds file.

## Credits

- **[@ghosthgy](https://github.com/ghosthgy/openwrt-msm8916)** - Initial project foundation
- **[@lkiuyu](https://github.com/lkiuyu/immortalwrt)** - MSM8916 support, patches, and OpenStick feeds
- **[@Mio-sha512](https://github.com/Mio-sha512/OpenStick-Builder)** - USB gadget and firmware loader concepts
- **[@AlienWolfX](https://github.com/AlienWolfX/UZ801-USB_MODEM/wiki/Troubleshooting)** - Carrier policy troubleshooting guide
- **[@gw826943555](https://github.com/gw826943555/luci-app-tailscale) & [@asvow](https://github.com/asvow)** - Tailscale LuCI application