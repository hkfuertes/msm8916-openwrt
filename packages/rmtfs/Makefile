#
# Copyright (C) 2020-2021 HandsomeMod Project
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=rmtfs
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/rmtfs-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/linux-msm/rmtfs
PKG_SOURCE_VERSION:=586372e575f5cc1a7cbb170219ab6df98f394cae

PKG_LICENSE:=BSD-3-Clause

include $(INCLUDE_DIR)/package.mk

define Package/rmtfs
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Qualcomm Remote Filesystem Service Implementation
  DEPENDS:=+libudev-zero +libqrtr +qrtr-utils
endef

define Build/Compile
	$(call Build/Compile/Default,rmtfs)
endef

define Package/rmtfs/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/rmtfs.init $(1)/etc/init.d/rmtfs

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rmtfs $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,rmtfs))
