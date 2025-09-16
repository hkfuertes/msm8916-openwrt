## OpenWrt for uz801
Moderm version of OpenWrt working on UZ801v3.

### Features
- Modem Working
  - No Rx/Tx displayed in luci interface (?)
- Wifi Working
- USB gadget working (NCM, RNDIS, MASS, ACM tested!)
  - No shell attached to ACM, just pure raw Serial (/dev/ttyGS0)
- TUN installed
- Wireguard Installed
- GRE Protocol Installed

### TODO:
- Convert `mods/*` into separated packages so no need to patch oficial repo.
- Github Action Build pipeline
- Use built dtb from openstick-builder?
  - use linux's dts?
- ModemManager not showing Rx/Tx
- `msm-firmware-loader`, to mount firmware instead of bundle to free up almost 40mb from rootfs.
  - For more info: [packages/msm-firmware-loader/readme.md](packages/msm-firmware-loader/readme.md)
- Remove extra feed from apk installer:
  - This feed does nothing as its pointing to msm89xx/msm8916 wich does not exist.
  - /etc/apk/repositories.d/distfeeds.list
- Fix version to latest (instead of snapshot) OpenWrt 24.10.2
- Add `opkg` and make it work with `luci`.
- Review `firmware-selector` default selection of packages:
  - Investigare ImageBuilder
  - Firmware selector default packages for mt300n (mango): 
  ```
    base-files ca-bundle dnsmasq dropbear firewall4 fstools kmod-gpio-button-hotplug kmod-leds-gpio
    kmod-mt7603 kmod-nft-offload libc libgcc libustream-mbedtls logd mtd netifd nftables
    odhcp6c odhcpd-ipv6only opkg ppp ppp-mod-pppoe swconfig uci uclient-fetch urandom-seed
    urngd wpad-basic-mbedtls kmod-usb2 kmod-usb-ohci luci
  ```
---
### Stuff
- The `msm8916-yiming-uz801v3.dtb` file is a prebuilt dtb extracted from one of the many OpenStick-Builder project living in Github.
