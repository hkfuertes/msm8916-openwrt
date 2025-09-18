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
- USB gadget working (NCM, RNDIS, MASS, ACM tested!)
  - No shell attached to ACM, just pure raw Serial (/dev/ttyGS0)
- TUN installed
- Wireguard Installed
- GRE Protocol Installed
- `init.d` script to manage leds, only on/off if iface, no blinking:
  - Led init script: [packages/uz801-tweaks/files/smart_leds](packages/uz801-tweaks/files/smart_leds)
  - Activity trigger installed but not in use, _**deactivate init script and add led configs from luci or uci if needed.**_

### How to build OpenWrt
Docker is required!
```bash
cd devenv
docker compose run --rm builder # This will open bash inside a build environment
cp /repo/diffconfig .config # Copies the config on to the working folder
make defconfig
make -j$(nproc)
```

### How to flash from OEM
The base partitions are in a folder called `base_partitions` on this repo:
- Install `edl`: https://github.com/bkerler/edl
- Put the device in `edl` mode: https://wiki.postmarketos.org/wiki/Zhihe_series_LTE_dongles_(generic-zhihe)#How_to_enter_flash_mode
- Run `cd base_partitions && ./flash.sh`. The script will backup the important partitions specific for your device, will flash everything and will restore de previously saved partitions. In the middle of the script will halt and ask you to drag the boot and rootfs (system) partitions.

After the succesfull flash if you:
- Want to enter `fastboot`, just insert the device with the button pressed.
- Want to enter `edl`, boot into fastboot and execute: `fastboot oem reboot-edl`.

### Future:
- Custom package server for msm89xx/8916
  - Right now the first source from `distfeeds`, related to this specific target will fail as it won't exist. Any module not present might required to be built from sources. This repo can be used to do that, run `make menuconfig` before `make -j$(nproc)` and select it from the menu.
- Option to attach shell to ACM Gadget in `msm8916-usb-gadget.conf`
- `msm-firmware-loader`, to mount firmware instead of bundle to free up almost 40mb from rootfs.
  - For more info: [packages/msm-firmware-loader/readme.md](packages/msm-firmware-loader/readme.md)

## Credits
- @ghosthgy https://github.com/ghosthgy/openwrt-msm8916: Starting point for this project.
- @lkiuyu https://github.com/lkiuyu/immortalwrt: Almost all the msm8916 folder + patches + openstick feeds.
- @Mio-sha512 https://github.com/Mio-sha512/OpenStick-Builder: `usb-gadget` and `msm-firmware-loader` idea.
- @gw826943555 and @asvow https://github.com/gw826943555/luci-app-tailscale: Application for controlling tailscale from luci.
