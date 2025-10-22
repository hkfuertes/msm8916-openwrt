include $(TOPDIR)/rules.mk

PKG_NAME:=configs-dongle
PKG_VERSION:=1.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=Utilities
  CATEGORY:=Utilities
  TITLE:=Default Settings For Dongles
  DEPENDS:=+PACKAGE_luci:luci-proto-modemmanager +ledcontrol +kmod-button-hotplug +inotifywait
endef

# Optional description
define Package/$(PKG_NAME)/description
Tweaks and defaults for Dongles, including cleanup of problematic APK feeds.
endef

define Build/Configure
endef

define Build/Compile
endef

# Install configuration files and payload you already had
define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/uci_defaults $(1)/etc/uci-defaults/99-default-config

	$(INSTALL_DIR) $(1)/root/
	$(INSTALL_BIN) ./files/luci-app-tailscale*.apk $(1)/root/

	$(INSTALL_DIR) $(1)/etc/hotplug.d/ieee80211
	$(INSTALL_DATA) ./files/99-wifi-led $(1)/etc/hotplug.d/ieee80211/
	
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DATA) ./files/99-modem-led $(1)/etc/hotplug.d/iface/
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
