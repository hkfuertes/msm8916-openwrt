![OpenWrt logo](https://raw.githubusercontent.com/openwrt/openwrt/refs/heads/main/include/logo.png)

OpenWrt Project is a Linux operating system targeting embedded devices. Instead
of trying to create a single, static firmware, OpenWrt provides a fully
writable filesystem with package management. This frees you from the
application selection and configuration provided by the vendor and allows you
to customize the device through the use of packages to suit any application.
For developers, OpenWrt is the framework to build an application without having
to build a complete firmware around it; for users this means the ability for
full customization, to use the device in ways never envisioned.

### Features
Modern version of OpenWrt working on UZ801v3:
- Modem Working
  - No Rx/Tx displayed in luci interface (?)
- Wifi Working
- USB gadget working (NCM, RNDIS, MASS, ACM tested!)
  - No shell attached to ACM, just pure raw Serial (/dev/ttyGS0)
- TUN installed
- Wireguard Installed
- GRE Protocol Installed

### TODO:
- Default Device Trees:
  - SNAPSHOT (main) Working!
  - 24.10 Not Working! (maybe remove patches)
  - Provided dtb (blue color) _**in use**_ 
    - _...from one of the many OpenStick-Builder project living in Github._
- ModemManager not showing Rx/Tx
- `msm-firmware-loader`, to mount firmware instead of bundle to free up almost 40mb from rootfs.
  - For more info: [packages/msm-firmware-loader/readme.md](packages/msm-firmware-loader/readme.md)

### Future:
- Custom package server for msm89xx/8916


