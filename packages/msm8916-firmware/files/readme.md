## Preparation:
- Add here the `modem.bin` and `persist.bin` partitions from your device.
```bash
  # Read the partitions from Stock Android
  edl r modem modem.bin
  edl r persist persist.bin
```
- Add the package as dependency to the target:
```Makefile
define Device/yiming-uz801v3
  ...
  DEVICE_PACKAGES := ... msm8916-wcnss-firmware msm8916-wcnss-nv msm8916-modem-firmware
  ...
endef
TARGET_DEVICES += yiming-uz801v3
```