
include $(TOPDIR)/rules.mk

PKG_NAME:=configs-sp970
PKG_VERSION:=1.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=Utilities
  CATEGORY:=Utilities
  TITLE:=Defaults Setting For sp970
  DEPENDS:=+PACKAGE_luci:luci-proto-modemmanager
endef

# (Opcional) Descripción
define Package/$(PKG_NAME)/description
Tweaks y defaults para sp970, incluyendo limpieza de feeds APK problemáticos.
endef

define Build/Configure
endef

define Build/Compile
endef

# Instala ficheros de configuración y payload que ya tenías
define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/uci_defaults $(1)/etc/uci-defaults/99-default-config

	$(INSTALL_DIR) $(1)/root/
	$(INSTALL_DATA) ./files/luci-app-tailscale*.apk $(1)/root/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/uim_selection $(1)/etc/init.d/

	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) ./files/mcfg_sw.mbn $(1)/lib/firmware/MCFG_SW.MBN
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
set -e
FILE="/etc/apk/repositories.d/distfeeds.list"
ROOT="$${IPKG_INSTROOT:-/}"
TARGET_FILE="$$ROOT$$FILE"

if [ -f "$$TARGET_FILE" ]; then
	sed -i '\|/targets/msm89xx/msm8916/packages|d' "$$TARGET_FILE" || true
fi

exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
