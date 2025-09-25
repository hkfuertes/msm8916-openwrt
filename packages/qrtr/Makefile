# Copyright (C) 2025
# SPDX-License-Identifier: BSD-3-Clause

include $(TOPDIR)/rules.mk

PKG_NAME:=qrtr
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/linux-msm/qrtr.git
# Commit que estás usando
PKG_SOURCE_VERSION:=5923eea97377f4a3ed9121b358fd919e3659db7b

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

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
  TITLE:=Userspace library for Linux kernel QRTR
endef

define Package/qrtr-utils
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=+libqrtr
  TITLE:=QRTR tools and daemon (qrtr-ns, lookup, etc.)
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/*.h $(1)/usr/include/ || true

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libqrtr*.so* $(1)/usr/lib/ || true
endef

define Package/libqrtr/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libqrtr*.so* $(1)/usr/lib/ || true
endef

define Package/qrtr-utils/install
	# Binarios en /usr/bin
	$(INSTALL_DIR) $(1)/usr/bin
	-$(CP) $(PKG_INSTALL_DIR)/usr/bin/qrtr* $(1)/usr/bin/ 2>/dev/null || true

	# Daemon en /usr/sbin
	$(INSTALL_DIR) $(1)/usr/sbin
	-$(CP) $(PKG_INSTALL_DIR)/usr/sbin/qrtr-ns $(1)/usr/sbin/ 2>/dev/null || true

	# Init script (opcional): coloca files/qrtrns.init para procd
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/qrtrns.init $(1)/etc/init.d/qrtrns
endef

$(eval $(call BuildPackage,libqrtr))
$(eval $(call BuildPackage,qrtr-utils))
