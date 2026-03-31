# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

BOARD:=msm89xx
BOARDNAME:=Boards based on Snapdragon 210/410/615 chipsets
FEATURES:=ext4 usb usbgadget gpio fpu rootfs-part boot-part squashfs
SUBTARGETS:=msm8916

# Resolve kernel: prefer $1, fall back to latest available
kernel-detect = $(if $(wildcard $(TOPDIR)/include/kernel-$(1)),$(1),$(lastword $(sort $(patsubst $(TOPDIR)/include/kernel-%,%,$(wildcard $(TOPDIR)/include/kernel-[0-9]*)))))

KERNEL_PATCHVER:=$(call kernel-detect,6.12)


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
