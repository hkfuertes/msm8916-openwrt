include $(TOPDIR)/rules.mk

PKG_NAME:=configs-mifi
PKG_VERSION:=1.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=Utilities
  CATEGORY:=Utilities
  TITLE:=Default Settings For MiFis
  DEPENDS:=+PACKAGE_luci:luci-proto-modemmanager +ledcontrol +kmod-button-hotplug
endef

# Optional description
define Package/$(PKG_NAME)/description
Tweaks and defaults for MiFis, including cleanup of problematic APK feeds and LuCI battery widget.
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	
	# Copy uci_defaults and remove any trailing "exit 0"
	$(INSTALL_BIN) ./files/uci_defaults $(PKG_BUILD_DIR)/99-default-config
	
	# Add blank line separator
	echo "" >> $(PKG_BUILD_DIR)/99-default-config
	echo "# ========== Power button handler ==========" >> $(PKG_BUILD_DIR)/99-default-config
	echo "" >> $(PKG_BUILD_DIR)/99-default-config
	
	# Generate cat > /etc/rc.button/power command
	echo "cat > /etc/rc.button/power << 'EOF'" >> $(PKG_BUILD_DIR)/99-default-config
	cat ./files/rc.button.power >> $(PKG_BUILD_DIR)/99-default-config
	echo "EOF" >> $(PKG_BUILD_DIR)/99-default-config
	echo "chmod +x /etc/rc.button/power" >> $(PKG_BUILD_DIR)/99-default-config
	echo "" >> $(PKG_BUILD_DIR)/99-default-config
	echo "exit 0" >> $(PKG_BUILD_DIR)/99-default-config
endef

define Build/Configure
endef

define Build/Compile
endef

# Install configuration files and payload you already had
define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/99-default-config $(1)/etc/uci-defaults/99-default-config

	$(INSTALL_DIR) $(1)/root/
	$(INSTALL_BIN) ./files/luci-app-tailscale*.apk $(1)/root/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/admin_status/index
	$(INSTALL_DATA) ./files/battery.htm $(1)/usr/lib/lua/luci/view/admin_status/index/20_battery.htm

	$(INSTALL_DIR) $(1)/etc/hotplug.d/ieee80211
	$(INSTALL_DATA) ./files/hotplugs/99-wifi-led $(1)/etc/hotplug.d/ieee80211/
	
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DATA) ./files/hotplugs/99-modem-led $(1)/etc/hotplug.d/iface/

	$(INSTALL_DIR) $(1)/etc/hotplug.d/button
	$(INSTALL_DATA) ./files/hotplugs/50-battery-show $(1)/etc/hotplug.d/button/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/battery-monitor.init $(1)/etc/init.d/battery-monitor
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
