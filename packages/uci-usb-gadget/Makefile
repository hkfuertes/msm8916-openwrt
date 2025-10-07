include $(TOPDIR)/rules.mk

PKG_NAME:=uci-usb-gadget
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Miguel Fuertes <hkfuertes@gmail.com>
PKG_LICENSE:=GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Universal USB Gadget Manager
  DEPENDS:=@USB_GADGET_SUPPORT +bash +kmod-usb-gadget +kmod-usb-gadget-eth +kmod-usb-configfs
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  Universal USB Gadget Manager for OpenWrt using configfs.
  Supports RNDIS, ECM, NCM, ACM serial, and mass storage functions.
  Works on any Linux device with USB gadget support (Raspberry Pi, MSM8916, etc).
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/usbgadget
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	# Install main script
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usb-gadget.sh $(1)/usr/sbin/usb-gadget
	
	# Install init script
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/usb-gadget.init $(1)/etc/init.d/usb-gadget
	
	# Install UCI config
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/usbgadget.config $(1)/etc/config/usbgadget
	
	# Create storage directory
	$(INSTALL_DIR) $(1)/var/lib/usb-gadget
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	# Enable service on first install
	/etc/init.d/usb-gadget enable
	echo "USB Gadget service installed. Configure in /etc/config/usbgadget"
	echo "Start with: /etc/init.d/usb-gadget start"
}
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	# Stop and disable service before removal
	/etc/init.d/usb-gadget stop
	/etc/init.d/usb-gadget disable
}
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
