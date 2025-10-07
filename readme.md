![OpenWrt logo](https://raw.githubusercontent.com/openwrt/openwrt/refs/heads/main/include/logo.png)

OpenWrt Project is a Linux operating system targeting embedded devices. Instead
of trying to create a single, static firmware, OpenWrt provides a fully
writable filesystem with package management. This frees you from the
application selection and configuration provided by the vendor and allows you
to customize the device through the use of packages to suit any application.
For developers, OpenWrt is the framework to build an application without having
to build a complete firmware around it; for users this means the ability for
full customization, to use the device in ways never envisioned.

### This repository
Modern version of OpenWrt working on UZ801v3:
- Modem Working
  - ModemManager not showing Rx/Tx in Luci
- Wifi Working
- USB gadget (NCM, RNDIS, MASS, ACM Shell)
  - Configure via [uci](packages/uci-usb-gadget/readme.md) or `luci` app.
- TUN installed
- Wireguard Installed
- `hotplug.d` scripts to manage leds, only on/off if iface, no blinking:
  - On default Linux Kernel `dts`, leds are swapped!
  - Wifi Led: [packages/ledcontrol/files/99-modem-led](packages/ledcontrol/files/99-modem-led)
  - Modem Led: [packages/ledcontrol/files/99-wifi-led](packages/ledcontrol/files/99-wifi-led)
- ~~Firmware is dumped on first boot from modem/persist partition:~~
  - ~~Uses the binaries/firmware from the own device.~~
  - __*This will return eventually...*__
- Leaves the `luci-app-tailscale` package in `/root` ready to be installed:
  - It is not auto installed as it will install `tailscale` that is a heavy package and not everyone is using tailscale.
  - `apk add --allow-untrusted /root/luci-app-tailscale*.apk`
- **SquashFS and OverlayFS**:
  - The image no longer uses `ext4` for rootfs, instead it uses `squashfs`.
  - This allows for an overlay `ext4` partition to be used and enables `firstboot` (factory reset) mechanism.


### How to build OpenWrt
Docker is required!
```bash
cd devenv
docker compose run --rm builder # This will open bash inside a build environment
cp /repo/diffconfig .config # Copies the config on to the working folder
echo "# CONFIG_SIGNED_PACKAGES is not set" >> .config # Optional: Disable APK signature verification
make defconfig
make -j$(nproc)
```

### How to flash from OEM
- Install `edl`: https://github.com/bkerler/edl
- Put the device in `edl` mode: https://wiki.postmarketos.org/wiki/Zhihe_series_LTE_dongles_(generic-zhihe)#How_to_enter_flash_mode
- Do a full backup: `edl rf backup.bin`
- Run `./openwrt-msm89xx-msm8916-yiming-uz801v3-flash.sh`: The script will backup the important partitions specific for your device, will flash everything and will restore de previously saved partitions.

After the succesful flash if you:
- Want to enter `fastboot`, just insert the device with the button pressed.
- Want to enter `edl`, boot into fastboot and execute: `fastboot oem reboot-edl`.

### No Network/Modem Stuck at Searching

First, extract the contents of `modem.bin` from your firmware dump. You can do `eld r modem modem.bin`. In linux, its a simple image, you can mount it. Once you have it mounted, navigate to this directory: `image/modem_pr/mcfg/configs/mcfg_sw/generic/` and choose the folder according to your region:

- **APAC** - Asia Pacific
- **CHINA** - China
- **COMMON** - Use this if your region is not listed
- **EU** - Europe
- **NA** - North America
- **SA** - South America
- **SEA** - South East Asia

Once you have selected your region, you'll find folders typically representing Telcos in your area. Navigate through the appropriate folder until you locate `mcfg_sw.mbn`. If your telco is not listed, just grab a generic as it is done in this project for europe:
```makefile
  # packages/msm8916-firmware/Makefile
  define Build/Compile
      ...
  		::image/modem_pr/mcfg/configs/mcfg_sw/generic/common/default/default/mcfg_sw.mbn $(PKG_BUILD_DIR)
      ...
  endef
```

#### To apply the fix:
1. Transfer the file to your dongle: `scp -O mcfg_sw.mbn root@192.168.1.1:/lib/firmware/MCFG_SW.MBN`
   - **Capitalization matters!** Modem expects it to be all caps.
3. Reboot the device.

### Future:
- Recover `msm-firmware-dumper`.
- Custom package server for msm89xx/msm8916
  - Any target specific module not present might require to be built from sources. This repo can be used to do that, run `make menuconfig` before `make -j$(nproc)` and select it from the menu.
  - Feed:  `https://downloads.openwrt.org/snapshots/targets/msm89xx/msm8916/packages/packages.adb` has been removed from distfeeds file.
- Investigate `lpac` and eSIM.
- Reboot to edl/bootloader from linux/luci.
- Swap? Zram?... expand ram with eMMC?
- usb-gadget: HOST_MODE flag, to not enter gadget mode.
  - `luci-app-gadget-mode`

## Credits
- @ghosthgy https://github.com/ghosthgy/openwrt-msm8916
  - Starting point for this project.
- @lkiuyu https://github.com/lkiuyu/immortalwrt
  - Almost all the msm8916 folder + patches + openstick feeds.
- @Mio-sha512 https://github.com/Mio-sha512/OpenStick-Builder
  - `usb-gadget` and `msm-firmware-loader` idea (now `msm-firmware-dumper`).
- @AlienWolfX https://github.com/AlienWolfX/UZ801-USB_MODEM/wiki/Troubleshooting
  - For the carriers policy troubleshooting.
- @gw826943555 and @asvow https://github.com/gw826943555/luci-app-tailscale
  - Application for controlling tailscale from luci.
