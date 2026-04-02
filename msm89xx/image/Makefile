# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk


define Build/Compile
	$(CP) $(LINUX_DIR)/COPYING $(KDIR)/COPYING.linux
endef

### Image scripts ###
define Build/aboot-img
	mkbootimg \
		--kernel $@ \
		--ramdisk /dev/null \
		--cmdline $(CMDLINE) \
		-o $@.new
	mv $@.new $@
endef

define Build/msm89xx-sysupgrade
	rm -rf $@.sysupgrade-tmp
	mkdir -p $@.sysupgrade-tmp
	cp $(IMAGE_KERNEL) $@.sysupgrade-tmp/boot
	cp $@ $@.sysupgrade-tmp/rootfs
	cd $@.sysupgrade-tmp && \
		tar -cf $@.new --owner=0 --group=0 boot rootfs
	mv $@.new $@
	rm -rf $@.sysupgrade-tmp
endef

### Devices ###
define Device/Default
	PROFILES := Default
	KERNEL = kernel-bin | gzip | append-dtb | aboot-img
	IMAGES := boot.img system.img sysupgrade.bin
	IMAGE/boot.img := append-kernel | append-metadata
	IMAGE/system.img := append-rootfs | append-metadata
	IMAGE/sysupgrade.bin := append-rootfs | pad-rootfs | msm89xx-sysupgrade | append-metadata
	DEVICE_DTS_DIR := $(DTS_DIR)/qcom
	DEVICE_DTS = $$(SOC)-$(lastword $(subst _, ,$(1)))
	CMDLINE := "earlycon console=ttyMSM0,115200 rw"
endef

include $(SUBTARGET).mk

$(eval $(call BuildImage))
