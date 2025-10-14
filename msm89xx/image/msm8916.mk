# SPDX-License-Identifier: GPL-2.0-only

ifeq ($(SUBTARGET),msm8916)

define Build/generate-squashfs-gpt
  chmod +x $(TOPDIR)/target/linux/$(BOARD)/image/generate_squahsfs_gpt.sh
  $(TOPDIR)/target/linux/$(BOARD)/image/generate_squahsfs_gpt.sh $@
endef

define Build/install-flasher
  $(CP) $(TOPDIR)/target/linux/$(BOARD)/image/flash.sh $@
  chmod +x $@
endef

define Build/generate-firmware
  chmod +x $(TOPDIR)/target/linux/$(BOARD)/image/generate_firmware.sh
  $(TOPDIR)/target/linux/$(BOARD)/image/generate_firmware.sh $@
endef

define Device/msm8916
  SOC := msm8916
  CMDLINE := "earlycon console=tty0 console=ttyMSM0,115200 root=/dev/mmcblk0p14 rootfstype=squashfs rootwait"
  FEATURES := squashfs
  IMAGE/system.img := append-rootfs | append-metadata | sparse-img
  ARTIFACTS := squashfs-gpt_both0.bin flash.sh firmware.zip
  ARTIFACT/squashfs-gpt_both0.bin := generate-squashfs-gpt
  ARTIFACT/flash.sh := install-flasher
  ARTIFACT/firmware.zip := generate-firmware
endef

define Device/yiming-uz801v3
  $(Device/msm8916)
  DEVICE_VENDOR := YiMing
  DEVICE_MODEL := uz801v3
  FILESYSTEMS := squashfs
  DEVICE_PACKAGES := configs-uz801 wpad-basic-wolfssl rmtfs uci-usb-gadget \
                     block-mount f2fs-tools prepare-rootfs-data \
                     msm-firmware-dumper ledcontrol
endef
TARGET_DEVICES += yiming-uz801v3

define Device/generic-mf68e
  $(Device/msm8916)
  DEVICE_VENDOR := Generic
  DEVICE_MODEL := MF68E
  FILESYSTEMS := squashfs
  DEVICE_PACKAGES := configs-mf68e wpad-basic-wolfssl rmtfs uci-usb-gadget \
                     block-mount f2fs-tools prepare-rootfs-data \
                     msm-firmware-dumper power-button-daemon kmod-fbtft-gc9107 rgb2rbg
endef
TARGET_DEVICES += generic-mf68e

endif
