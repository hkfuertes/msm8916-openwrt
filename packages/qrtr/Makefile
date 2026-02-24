# SPDX-License-Identifier: BSD-3-Clause

include $(TOPDIR)/rules.mk

PKG_NAME:=qrtr
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/linux-msm/qrtr.git
PKG_SOURCE_VERSION:=5923eea97377f4a3ed9121b358fd919e3659db7b

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Miguel Fuertes <hkfuertes@gmail.com>

PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/meson.mk

MESON_ARGS += \
	-Ddefault_library=shared \
	-Dqrtr-ns=enabled \
	-Dsystemd-service=disabled

define Package/libqrtr
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=Qualcomm IPC Router userspace library
endef

define Package/qrtr-utils
	SECTION:=utils
	CATEGORY:=Utilities
	DEPENDS:=+libqrtr
	TITLE:=Qualcomm IPC Router tools and nameservice daemon
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/*.h $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libqrtr*.so* $(1)/usr/lib/
endef

define Package/libqrtr/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libqrtr*.so* $(1)/usr/lib/
endef

define Package/qrtr-utils/install
	$(INSTALL_DIR) $(1)/usr/bin
	-$(CP) $(PKG_INSTALL_DIR)/usr/bin/qrtr* $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/sbin
	-$(CP) $(PKG_INSTALL_DIR)/usr/sbin/qrtr-ns $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/qrtrns.init $(1)/etc/init.d/qrtrns
endef

$(eval $(call BuildPackage,libqrtr))
$(eval $(call BuildPackage,qrtr-utils))
