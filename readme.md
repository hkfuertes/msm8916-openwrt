![OpenWrt logo](https://raw.githubusercontent.com/openwrt/openwrt/refs/heads/main/include/logo.png)

Modern OpenWrt build targeting MSM8916 devices with full modem, USB gadget, and WiFi support.

## Table of Contents

- [About OpenWrt](#about-openwrt)
- [Supported Devices](#supported-devices)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Building](#building)
- [Installation](#installation)
  - [Flashing from OEM Firmware](#flashing-from-oem-firmware)
  - [Accessing Boot Modes](#accessing-boot-modes)
- [Troubleshooting](#troubleshooting)
  - [No Network / Modem Stuck at Searching](#no-network--modem-stuck-at-searching)
- [Band Configuration (UF02)](#band-configuration-uf02)
- [Roadmap](#roadmap)
- [Credits](#credits)

---

## About OpenWrt

OpenWrt Project is a Linux operating system targeting embedded devices. Instead of trying to create a single, static firmware, OpenWrt provides a fully writable filesystem with package management. This frees you from the application selection and configuration provided by the vendor and allows you to customize the device through the use of packages to suit any application.

## Supported Devices

All devices use the Qualcomm MSM8916 SoC with 384 MB RAM and 4 GB eMMC.

- **UZ801v3** (`yiming-uz801v3`) -- USB dongle form factor.
- **UF02** (`generic-uf02`) -- USB dongle form factor, ships with Asian bands only. European bands can be enabled via `nv_manager.py` + `bands_european_uz801.json` — see [Band Configuration](#band-configuration-uf02).

MF68E and M9S device support has been moved to the [TBR](TBR/readme.md) directory for reference. See that README for re-integration instructions.

## Features

### Working Components
- **Modem**: Fully functional with cellular connectivity
  - ModemManager Rx/Tx stats not displayed in LuCI (known issue)
- **WiFi**: Complete wireless support
- **USB Gadget Modes**: NCM, RNDIS, Mass Storage, ACM Shell
  - Configure via [UCI](packages/uci-usb-gadget/readme.md) or LuCI app
- **VPN Ready**: TUN driver and WireGuard pre-installed
- **LED Control**: Managed via `hotplug.d` scripts (sysfs-based, no extra packages)

### Storage & Recovery
- **SquashFS Root**: Compressed root filesystem
- **OverlayFS**: ext4 overlay partition for user data (formatted automatically via preinit)
- **Factory Reset**: `firstboot` mechanism enabled

### Additional Packages
- **Tailscale**: LuCI app available as standalone package (APK and IPK)

## Prerequisites

- Docker installed on your system
- Basic knowledge of Linux command line
- For flashing: [edl tool](https://github.com/bkerler/edl)

## Building

### GitHub Actions (release builds)

GHA workflows automatically resolve the **latest OpenWrt 25.12.x** tag. Trigger manually from the Actions tab:

- **Build firmware**: `build.yml` — select a device (`uz801`, `uf02`, or `all`)
- **Build packages**: `build-package.yml` — builds `luci-app-tailscale`, `uci-usb-gadget`, and `luci-app-usb-gadget` in APK and IPK formats

### Local (snapshot builds)

1. Build the environment (defaults to OpenWrt `main`/snapshot):
```
cd devenv
docker compose build builder
```

2. Enter and build:
```
docker compose run --rm builder
cp /repo/diffconfig_uz801 .config
make defconfig
make -j$(nproc)
```

To build a specific release locally:
```
OPENWRT_VERSION=v24.10.2 docker compose build builder --no-cache
```

> **Supported versions:** OpenWrt 25.12.x and current snapshots (kernel 6.12). OpenWrt 24.10.x (kernel 6.6) compiles but does not boot — the Makefile supports it via `KERNEL_FOR_24` (currently commented out) if someone wants to investigate further.

## Installation

### Flashing from OEM Firmware

1. **Install EDL tool**: https://github.com/bkerler/edl
2. **Enter EDL mode**:
   - **UZ801v3**: See [PostmarketOS wiki guide](https://wiki.postmarketos.org/wiki/Zhihe_series_LTE_dongles_(generic-zhihe)#How_to_enter_flash_mode)

3. **Backup original firmware**:
   ```
   edl rf backup.bin
   ```

4. **Flash OpenWrt**:
   ```
   ./openwrt-msm89xx-msm8916-*-flash.sh
   ```

   > The script flashes entirely via EDL (no fastboot step). It automatically backs up radio partitions, writes the new GPT, firmware, boot and rootfs, and restores the backed-up partitions.

### Accessing Boot Modes

#### UZ801v3
- **Fastboot mode**: Insert device while holding the button
- **EDL mode**: Boot to fastboot first, then execute: `fastboot oem reboot-edl`

#### UF02
- **Fastboot mode**:
  - From OEM: `adb reboot bootloader`.
  - From OpenWrt: Enter `edl` and erase boot partition (`edl e boot`).
- **EDL mode**:
  - From OEM: `adb reboot bootloader`, flash `lk2nd` aboot. Reboot pressing the button.
  - From OpenWrt: Insert device while holding the button.

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

## Band Configuration (UF02)

The UF02 ships with Asian bands only. RF band configuration is stored in the modem's NV/EFS partition and can be updated using the included `nv_manager.py` script and a pre-built band config JSON.

A validated European band config (`bands_european_uz801.json`) is included, extracted from a UZ801v3 running European firmware:

| | Bands |
|---|---|
| **Before** | WCDMA B1/B5/B8 · LTE B1/B3/B5/B8 |
| **After** | WCDMA B1/B8 · LTE B1/B3/B5/B7/B8/B38/B40/B41 |

> **Note:** LTE B20 (800 MHz) is a hardware limitation of the UF02 RF front-end and cannot be enabled via software.

### Requirements

- Linux host with ADB and Python 3
- `pyserial`: `pip install pyserial`
- Device running its OEM Android firmware

### Procedure

**1. Get ADB root:**
```bash
# Try this first (works on some devices):
adb root

# If that doesn't work (UF02), use:
adb shell "setprop service.adb.root 1; busybox killall adbd"
sleep 3
adb shell id   # should show uid=0(root)
```

**2. Enable DIAG port:**
```bash
adb shell setprop sys.usb.config diag,adb
```

**3. Bind the DIAG interface on the host:**
```bash
sudo modprobe option
sudo sh -c 'echo "05c6 901d" > /sys/bus/usb-serial/drivers/option1/new_id'
sudo chmod a+rw /dev/ttyUSB0
```

**4. Apply the European band config:**
```bash
python3 nv_manager.py --port /dev/ttyUSB0 --apply-bands bands_european_uz801.json
```

**5. Reboot:**
```bash
adb shell reboot
```

### Capturing bands from another device

To save the band NV items from any device as a JSON (e.g. a UZ801 with the desired config):
```bash
python3 nv_manager.py --port /dev/ttyUSB0 --read-bands my_bands.json
```

This saves NV items 946, 1877, 1878, 1881, 6828, 6829 — the full RF band configuration.

## Roadmap

- [ ] Custom package server for msm89xx/msm8916
  - Note: Target-specific modules may require building from source via `make menuconfig`
  - The target-specific APK feed is automatically removed on first boot (msm89xx is not on downloads.openwrt.org)
- [ ] Investigate `lpac` for eSIM support
- [x] Memory expansion: `kmod-zram` + `zram-swap` enabled on all devices

## Credits

- **[@ghosthgy](https://github.com/ghosthgy/openwrt-msm8916)** - Initial project foundation
- **[@lkiuyu](https://github.com/lkiuyu/immortalwrt)** - MSM8916 support, patches, and OpenStick feeds
- **[@Mio-sha512](https://github.com/Mio-sha512/OpenStick-Builder)** - USB gadget and firmware loader concepts
- **[@AlienWolfX](https://github.com/AlienWolfX/UZ801-USB_MODEM/wiki/Troubleshooting)** - Carrier policy troubleshooting guide
- **[@gw826943555](https://github.com/gw826943555/luci-app-tailscale) & [@asvow](https://github.com/asvow)** - Tailscale LuCI application
