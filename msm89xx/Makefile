# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

BOARD:=msm89xx
BOARDNAME:=Boards based on Snapdragon 210/410/615 chipsets
FEATURES:=ext4 usb usbgadget gpio fpu rootfs-part boot-part squashfs
SUBTARGETS:=msm8916

# Kernel version map: OpenWrt major -> kernel patchver
#KERNEL_FOR_24 := 6.6
KERNEL_FOR_25 := 6.12
KERNEL_DEFAULT := 6.12

OPENWRT_MAJOR := $(shell git -C $(TOPDIR) describe --tags --abbrev=0 2>/dev/null | cut -d. -f1 | tr -d v)
KERNEL_PATCHVER := $(or $(KERNEL_FOR_$(OPENWRT_MAJOR)),$(KERNEL_DEFAULT))


define Target/Description
	Build firmware images for various Snapdragon 210/410/615 based devices
endef

include $(INCLUDE_DIR)/target.mk

DEFAULT_PACKAGES += partx-utils e2fsprogs mkf2fs
DEFAULT_PACKAGES += kmod-usb-chipidea kmod-usb-gadget-eth
DEFAULT_PACKAGES += kmod-wcn36xx kmod-rproc-wcnss
DEFAULT_PACKAGES += kmod-rpmsg-wwan-ctrl kmod-bam-dmux kmod-qcom-rproc-modem
DEFAULT_PACKAGES += rmtfs

KERNELNAME:=Image

$(eval $(call BuildTarget))
