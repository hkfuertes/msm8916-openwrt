# SPDX-License-Identifier: BSD-3-Clause

include $(TOPDIR)/rules.mk

PKG_NAME:=msm-firmware-dumper
PKG_VERSION:=1.1
PKG_RELEASE:=1

PKG_LICENSE:=BSD-3-Clause
PKG_MAINTAINER:=Miguel Fuertes <hkfuertes@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Qualcomm firmware partition dump utility
	DEPENDS:=+kmod-fs-vfat +kmod-fs-ext4 +kmod-nls-cp437 +kmod-nls-iso8859-1
endef

define Package/$(PKG_NAME)/description
	Dumps Qualcomm firmware partitions into /lib/firmware on first boot.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/msm-firmware-dumper.sh $(1)/usr/bin/msm-firmware-dumper
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/msm-firmware-dumper.init $(1)/etc/init.d/msm-firmware-dumper
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
