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
  TITLE:=UCI-based USB Gadget Manager for OpenWrt
	DEPENDS:=@USB_GADGET_SUPPORT +kmod-fs-configfs +kmod-usb-gadget +kmod-usb-lib-composite +kmod-usb-gadget-serial +kmod-usb-gadget-mass-storage +kmod-usb-gadget-ncm +coreutils-truncate +coreutils-shuf +coreutils-dd
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  UCI-based USB Gadget Manager for OpenWrt using the kernel configfs interface.
  
  Provides easy configuration and management of USB gadget functions through UCI,
  making OpenWrt devices appear as various USB peripherals when connected to a host.
  
  Supported functions:
   - RNDIS: Windows-compatible USB ethernet (plug-and-play)
   - ECM: CDC Ethernet for macOS and Linux
   - NCM: Modern high-performance USB ethernet
   - ACM: Serial console (with optional login shell)
   - Mass Storage: Expose storage image as USB drive
  
  Features:
   - Hardware-agnostic: auto-detects UDC controller (works on Raspberry Pi, MSM8916,
     Orange Pi, and any device with USB gadget support)
   - Network integration: automatically adds USB ethernet interfaces to LAN bridge
   - Configurable via UCI: /etc/config/usbgadget
   - Persistent serial numbers based on machine-id
   - Deterministic MAC address generation
  
  Perfect for creating USB-based network access, serial consoles, or mass storage
  devices from OpenWrt routers and embedded devices.
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
