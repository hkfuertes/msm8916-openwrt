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
endef

define Device/yiming-uz801v3
  $(Device/msm8916)
  DEVICE_VENDOR := YiMing
  DEVICE_MODEL := uz801v3
  FILESYSTEMS := squashfs
  DEVICE_PACKAGES := uz801-tweaks wpad-basic-wolfssl rmtfs uci-usb-gadget \
                     block-mount f2fs-tools prepare-rootfs-data \
                     msm8916-wcnss-firmware msm8916-wcnss-nv msm8916-modem-firmware
  IMAGE/system.img := append-rootfs | append-metadata | sparse-img
  ARTIFACTS := squashfs-gpt_both0.bin flash.sh firmware.zip
  ARTIFACT/squashfs-gpt_both0.bin := generate-squashfs-gpt
  ARTIFACT/flash.sh := install-flasher
  ARTIFACT/firmware.zip := generate-firmware
endef
TARGET_DEVICES += yiming-uz801v3

endif
