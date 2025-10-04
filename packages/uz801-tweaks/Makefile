#
# Copyright (C) 2020-2022 HandsomeMod Project
#
# This is free software, licensed under the GNU General Public License v3.
#
#
include $(TOPDIR)/rules.mk

PKG_NAME:=uz801-tweaks
PKG_VERSION:=1.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=Utilities
	CATEGORY:=Utilities
	TITLE:=Defaults Setting For uz801v3
	DEPENDS:=+PACKAGE_luci:luci-proto-modemmanager
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install 
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/uci_defaults $(1)/etc/uci-defaults/99-default-config

	$(INSTALL_DIR) $(1)/root/
	$(INSTALL_BIN) ./files/luci-app-tailscale*.apk $(1)/root/
endef 

$(eval $(call BuildPackage,$(PKG_NAME)))
