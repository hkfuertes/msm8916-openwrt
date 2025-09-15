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
---
### Stuff
- The `msm8916-yiming-uz801v3.dtb` file is a prebuilt dtb extracted from one of the many OpenStick-Builder project living in Github.