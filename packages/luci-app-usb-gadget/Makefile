include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for USB Gadget Manager
LUCI_DESCRIPTION:=Web interface for managing USB gadget functions (RNDIS, ECM, NCM, ACM, Mass Storage)
LUCI_DEPENDS:=+uci-usb-gadget
LUCI_PKGARCH:=all

PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Miguel Fuertes <hkfuertes@gmail.com>
PKG_LICENSE:=GPL-2.0

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
