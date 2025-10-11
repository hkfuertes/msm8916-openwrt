include $(TOPDIR)/rules.mk

PKG_NAME:=power-button-daemon
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Power button monitor daemon
  DEPENDS:=+evtest
endef

define Package/$(PKG_NAME)/description
  Monitors power button and triggers poweroff on long press (3s).
  Designed for MSM8916-based devices with PM8916 PON.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/power_button_monitor.sh $(1)/usr/sbin/power_button_monitor

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/power_button.init $(1)/etc/init.d/power_button
endef

$(eval $(call BuildPackage,$(PKG_NAME)))