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

define Build/generate-firmware
  chmod +x $(TOPDIR)/target/linux/$(BOARD)/image/generate_firmware.sh
  $(TOPDIR)/target/linux/$(BOARD)/image/generate_firmware.sh $@
endef

define Build/generate-empty-rootfs-data
  chmod +x $(TOPDIR)/target/linux/$(BOARD)/image/generate_rootfs_data.sh
  $(TOPDIR)/target/linux/$(BOARD)/image/generate_rootfs_data.sh $@
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
  DEVICE_PACKAGES := uz801-tweaks wpad-basic-wolfssl rmtfs msm8916-usb-gadget \
                     block-mount f2fs-tools prepare-rootfs-data rootfs-resizer \
                     msm-firmware-dumper msm8916-wcnss-firmware msm8916-wcnss-nv msm8916-modem-firmware
  IMAGE/system.img := append-rootfs | append-metadata | sparse-img
  ARTIFACTS := gpt_both0.bin flash.sh firmware.zip rootfs_data.img
  ARTIFACT/gpt_both0.bin := generate-gpt
  ARTIFACT/flash.sh := install-flasher
  ARTIFACT/firmware.zip := generate-firmware
  ARTIFACT/rootfs_data.img := generate-empty-rootfs-data
endef
TARGET_DEVICES += yiming-uz801v3

endif
