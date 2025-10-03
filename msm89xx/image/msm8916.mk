# SPDX-License-Identifier: GPL-2.0-only

ifeq ($(SUBTARGET),msm8916)

define Build/generate-gpt-squashfs
    $(TOPDIR)/target/linux/$(BOARD)/image/generate_gpt.sh \
        "$(dir $@)" \
        $(TOPDIR)/target/linux/$(BOARD)/image/tables/gpt-squashfs.table \
        "$(notdir $@)"
endef

define Build/generate-gpt-ext4
    $(TOPDIR)/target/linux/$(BOARD)/image/generate_gpt.sh \
        "$(dir $@)" \
        $(TOPDIR)/target/linux/$(BOARD)/image/tables/gpt-ext4.table \
        "$(notdir $@)"
endef

define Build/install-flasher
    $(CP) $(TOPDIR)/target/linux/$(BOARD)/image/flash.sh $@
    chmod +x $@
endef

define Device/msm8916
  SOC := msm8916
  CMDLINE := "earlycon console=tty0 console=ttyMSM0,115200 root=/dev/mmcblk0p14 rootwait nowatchdog"
endef

define Device/yiming-uz801v3
  $(Device/msm8916)
  DEVICE_VENDOR := YiMing
  DEVICE_MODEL := uz801v3
  DEVICE_PACKAGES := uz801-tweaks wpad-basic-wolfssl msm-firmware-dumper rmtfs 
  # rootfs-resizer rootfs-data-formatter
  
  ifdef CONFIG_TARGET_ROOTFS_SQUASHFS
    IMAGE/system.img := append-rootfs | append-metadata
    ARTIFACTS += squashfs_gpt_both0.bin squashfs_rootfs_data.img flash.sh
    ARTIFACT/squashfs_gpt_both0.bin := generate-gpt-squashfs
    ARTIFACT/squashfs_rootfs_data.img := generate-gpt-squashfs
    ARTIFACT/flash.sh := install-flasher
  endif
  
  ifdef CONFIG_TARGET_ROOTFS_EXT4FS
    IMAGE/system.img := append-rootfs | append-metadata | sparse-img
    ARTIFACTS += ext4_gpt_both0.bin flash.sh
    ARTIFACT/ext4_gpt_both0.bin := generate-gpt-ext4
    ARTIFACT/flash.sh := install-flasher
  endif
endef
TARGET_DEVICES += yiming-uz801v3

endif
