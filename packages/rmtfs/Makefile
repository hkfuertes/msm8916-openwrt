# SPDX-License-Identifier: BSD-3-Clause

include $(TOPDIR)/rules.mk

PKG_NAME:=rmtfs
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/linux-msm/rmtfs
PKG_SOURCE_VERSION:=586372e575f5cc1a7cbb170219ab6df98f394cae

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Miguel Fuertes <hkfuertes@gmail.com>

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/rmtfs
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Qualcomm Remote Filesystem service daemon
	DEPENDS:=+libudev-zero +libqrtr +qrtr-utils
endef

define Build/Compile
	$(call Build/Compile/Default,rmtfs)
endef

define Package/rmtfs/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rmtfs $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/rmtfs.init $(1)/etc/init.d/rmtfs
endef

$(eval $(call BuildPackage,rmtfs))
