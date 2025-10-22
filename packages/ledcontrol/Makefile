include $(TOPDIR)/rules.mk

PKG_NAME:=ledcontrol
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/ledcontrol
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Simple LED control utility
  DEPENDS:=
endef

define Package/ledcontrol/description
  Simple utility to control device LEDs via sysfs
  Usage: ledcontrol <color:function> <on|off|blink|blink_fast>
  Includes hotplug scripts for WiFi and modem LED management
endef

define Build/Compile
endef

define Package/ledcontrol/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./ledcontrol.sh $(1)/usr/bin/ledcontrol
endef

$(eval $(call BuildPackage,ledcontrol))
