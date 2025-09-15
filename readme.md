## WRT for uz801
These are my attempts at building the os... my end goal is to build a working modern openwrt, but first I will start from immortalwrt from lkiuyu and the from official immortalwrt.

### Working
_**(On all Systems, lkiuyu, immoirtalwrt, openwrt)**_
- Modem Working
  - No Rx/Tx displayed in luci interface (?)
- Wifi Working
- USB gadget working (NCM, RNDIS, MASS, ACM tested!)
---
### TODO:
- Recover GHA build pipeline
- Use built dtb from openstick-builder?
  - use linux's dts?
- modemmanager not showing rxtx
- msm firmware loader, to free up almost 40mb from rootfs
- remove extra feed from apk installer
  - /etc/apk/repositories.d/distfeeds.list
- openwrt 24.10.2 (fixed version with opkg)
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