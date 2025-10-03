# SPDX-License-Identifier: GPL-2.0-only

ifeq ($(SUBTARGET),msm8916)

define Build/generate-gpt
    chmod +x $(TOPDIR)/target/linux/$(BOARD)/image/generate_gpt.sh
    $(TOPDIR)/target/linux/$(BOARD)/image/generate_gpt.sh $@
endef

define Build/install-flasher
    $(CP) $(TOPDIR)/target/linux/$(BOARD)/image/flash.sh $@
    chmod +x $@
endef

define Device/msm8916
  SOC := msm8916
  CMDLINE := "earlycon console=tty0 console=ttyMSM0,115200 root=/dev/mmcblk0p14 rootwait"
  FEATURES := ext4
  FILESYSTEMS := ext4
endef

define Device/yiming-uz801v3
  $(Device/msm8916)
  DEVICE_VENDOR := YiMing
  DEVICE_MODEL := uz801v3
  DEVICE_PACKAGES := uz801-tweaks wpad-basic-wolfssl msm-firmware-dumper rmtfs rootfs-resizer msm8916-usb-gadget
  IMAGE/system.img := append-rootfs | append-metadata | sparse-img
  ARTIFACTS := gpt_both0.bin flash.sh
  ARTIFACT/gpt_both0.bin := generate-gpt
  ARTIFACT/flash.sh := install-flasher
endef
TARGET_DEVICES += yiming-uz801v3

endif
