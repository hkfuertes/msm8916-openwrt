# Copyright (C) 2025
# SPDX-License-Identifier: BSD-3-Clause

include $(TOPDIR)/rules.mk

PKG_NAME:=qrtr
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/linux-msm/qrtr.git
PKG_SOURCE_VERSION:=5923eea97377f4a3ed9121b358fd919e3659db7b

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/meson.mk

# Ajustes Meson opcionales (ej.: tipo de build)
# MESON_ARGS += --buildtype=release

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

# Headers y .so para SDK
define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/*.h $(1)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libqrtr*.so* $(1)/usr/lib/
endef

# Biblioteca en su propio paquete
define Package/libqrtr/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libqrtr*.so* $(1)/usr/lib/
endef

# Herramientas y daemon
define Package/qrtr-utils/install
	$(INSTALL_DIR) $(1)/usr/bin
	# Instalar utilidades/daemon construidos por Meson
	# (p.ej. qrtr-ns, qrtr-lookup, qrtr-cmd si están presentes)
	-$(CP) $(PKG_INSTALL_DIR)/usr/bin/qrtr* $(1)/usr/bin/

	# Init script opcional (procd); coloque un files/qrtrns.init si se desea
	# $(INSTALL_DIR) $(1)/etc/init.d
	# $(INSTALL_BIN) ./files/qrtrns.init $(1)/etc/init.d/qrtrns
endef

$(eval $(call BuildPackage,libqrtr))
$(eval $(call BuildPackage,qrtr-utils))
