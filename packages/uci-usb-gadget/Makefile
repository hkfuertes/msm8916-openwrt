# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=uci-usb-gadget
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Miguel Fuertes <hkfuertes@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=UCI-based USB gadget manager
	DEPENDS:=@USB_GADGET_SUPPORT \
		+kmod-fs-configfs \
		+kmod-usb-gadget \
		+kmod-usb-lib-composite \
		+kmod-usb-gadget-serial \
		+kmod-usb-gadget-mass-storage \
		+kmod-usb-gadget-ncm \
		+coreutils-truncate \
		+coreutils-shuf \
		+coreutils-dd
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	UCI-based USB gadget manager using the kernel configfs interface.

	Configures OpenWrt devices as USB peripherals (RNDIS, ECM, NCM, ACM,
	Mass Storage) when connected to a host. Hardware-agnostic: auto-detects
	the UDC controller and integrates USB ethernet interfaces into the LAN bridge.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/usbgadget
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usb-gadget.sh $(1)/usr/sbin/usb-gadget
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/usb-gadget.init $(1)/etc/init.d/usb-gadget
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/usbgadget.config $(1)/etc/config/usbgadget
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/usb-gadget enable
}
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/usb-gadget stop
	/etc/init.d/usb-gadget disable
}
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
