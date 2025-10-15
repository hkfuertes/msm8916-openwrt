include $(TOPDIR)/rules.mk

PKG_NAME:=display-monitor
PKG_RELEASE:=1
PKG_VERSION:=1.0

include $(INCLUDE_DIR)/package.mk

define Package/display-monitor
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Display backlight monitor with timeout
  PKGARCH:=all
endef

define Package/display-monitor/description
  Automatic display backlight control with configurable timeouts.
  Monitors button events to wake the display.
endef

define Build/Compile
endef

define Package/display-monitor/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	
	$(INSTALL_BIN) ./files/display-monitor.sh $(1)/usr/bin/display-monitor
	$(INSTALL_BIN) ./files/display-monitor.init $(1)/etc/init.d/display-monitor
endef

define Package/display-monitor/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/display-monitor enable
	/etc/init.d/display-monitor start
}
exit 0
endef

define Package/display-monitor/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/display-monitor stop
	/etc/init.d/display-monitor disable
}
exit 0
endef

$(eval $(call BuildPackage,display-monitor))
