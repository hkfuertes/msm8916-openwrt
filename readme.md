![OpenWrt logo](https://raw.githubusercontent.com/openwrt/openwrt/refs/heads/main/include/logo.png)

Modern OpenWrt build targeting MSM8916 devices with full modem, display, and USB gadget support.

## Table of Contents

- [About OpenWrt](#about-openwrt)
- [Supported Devices](#supported-devices)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Building](#building)
- [Installation](#installation)
  - [Flashing from OEM Firmware](#flashing-from-oem-firmware)
  - [Accessing Boot Modes](#accessing-boot-modes)
- [Device-Specific Configuration](#device-specific-configuration)
  - [MiFi M68E Display & Power Management](#mifi-m68e-display--power-management)
- [Troubleshooting](#troubleshooting)
  - [No Network / Modem Stuck at Searching](#no-network--modem-stuck-at-searching)
- [Roadmap](#roadmap)
- [Credits](#credits)

---

## About OpenWrt

OpenWrt Project is a Linux operating system targeting embedded devices. Instead of trying to create a single, static firmware, OpenWrt provides a fully writable filesystem with package management. This frees you from the application selection and configuration provided by the vendor and allows you to customize the device through the use of packages to suit any application.

## Supported Devices

| Device | OpenWrt Target | SoC | RAM | Storage | Display | Battery | Notes |
|--------|----------------|-----|-----|---------|---------|---------|-------|
| **UZ801v3** | `yiming-uz801v3` | MSM8916 | 384MB | 4GB | ❌ | ❌ | USB dongle form factor |
| **MiFi M68E** | `generic-mf68e` | MSM8916 | 384MB | 4GB | ✅ GC9107 | ✅ | Portable hotspot with interactive display |

## Features

### Working Components
- **Modem**: Fully functional with cellular connectivity
  - ModemManager Rx/Tx stats not displayed in LuCI (known issue)
- **WiFi**: Complete wireless support
- **USB Gadget Modes**: NCM, RNDIS, Mass Storage, ACM Shell
  - Configure via [UCI](packages/uci-usb-gadget/readme.md) or LuCI app
- **Display**: GC9107 framebuffer support *(MiFi M68E only)*
  - System info screen with WiFi QR code
  - Configurable auto-dim and lockscreen timers
- **VPN Ready**: TUN driver and WireGuard pre-installed
- **LED Control**: Managed via `hotplug.d` scripts *(UZ801 Only)*
  - WiFi LED: [99-modem-led](packages/ledcontrol/files/99-modem-led)
  - Modem LED: [99-wifi-led](packages/ledcontrol/files/99-wifi-led)
- **Display Manager**: FIFO-based display control daemon *(MiFi M68E only)*
  - Script: [display-manager](packages/display-manager/files/display-manager.sh)
  - Manages brightness, timers, and power states
  - Commands: `full`, `dim`, `off`, `lockscreen`, `update`, `shutdown`
  - Controlled via `/var/run/display.fifo`

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

1. **Install EDL tool**: https://github.com/bkerler/edl
2. **Enter EDL mode**:
   - **UZ801v3**: See [PostmarketOS wiki guide](https://wiki.postmarketos.org/wiki/Zhihe_series_LTE_dongles_(generic-zhihe)#How_to_enter_flash_mode)
   - **MiFi M68E**: 
     - From OEM firmware: `adb reboot edl`
     - After flashing OpenWrt: Requires EDL cable or shorting test pads on PCB ([see forum guide](https://forum.openwrt.org/t/uf896-qualcomm-msm8916-lte-router-384mib-ram-2-4gib-flash-android-openwrt/131712/483))

3. **Backup original firmware**:
   ```
   edl rf backup.bin
   ```

4. **Flash OpenWrt**:
   ```
   ./openwrt-msm89xx-msm8916-*-flash.sh
   ```
   
   > The script automatically backs up device-specific partitions, flashes the firmware, and restores critical data.

### Accessing Boot Modes

#### UZ801v3
- **Fastboot mode**: Insert device while holding the button
- **EDL mode**: Boot to fastboot first, then execute: `fastboot oem reboot-edl`

#### MiFi M68E
- **Fastboot mode from OpenWrt**: Enter `edl` mode and erase boot partition (`edl e boot`). This will force bootloader.
- **EDL mode**: 
  - From OEM: `adb reboot edl`
  - From OpenWrt: Requires EDL cable or shorting PCB test pads

## Device-Specific Configuration

### MiFi M68E Display & Power Management

The MiFi M68E features an interactive display and power management system controlled via the power button and UCI configuration.

#### Power Button Functions
- **Single press**: Display system information screen
  - Shows: Carrier name, signal type (4G/3G), hostname, battery percentage, WiFi QR code
  - Automatically starts display timers
- **Double press** (quick succession): Power off the device

#### UCI Display Configuration

Configure display behavior through UCI:

```
# Display timers (in Seconds)
uci set display.display.timeout_dim='5'              # Seconds until screen dims (0 = disable)
uci set display.display.timeout_off='3'              # Seconds until screen turns off (0 = disable)
uci set display.display.enable_lockscreen='1'        # Show lockscreen when dimmed (0/1)

# Display brightness
uci set display.display.brightness_dim_divisor='8'   # Brightness divisor when dimmed (higher = dimmer)

# FIFO control (advanced)
uci set display.display.fifo='/var/run/display.fifo'

uci commit display
```

#### Display Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `timeout_dim` | integer | 5 | Minutes before display dims (0 = never) |
| `timeout_off` | integer | 3 | Minutes before display turns off (0 = never) |
| `enable_lockscreen` | boolean | 1 | Display lockscreen when dimmed |
| `brightness_dim_divisor` | integer | 8 | Brightness divisor for dim mode (higher value = dimmer) |
| `fifo` | string | `/var/run/display.fifo` | FIFO pipe for display control |

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
