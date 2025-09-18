# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2024 asvow

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI for Tailscale
LUCI_DEPENDS:=+tailscale
LUCI_PKGARCH:=all

PKG_VERSION:=1.2.6

define Package/luci-app-tailscale/postinst
#!/bin/sh
if [[ -f $${IPKG_INSTROOT}/etc/init.d/tailscale.luci ]]; then
	mv $${IPKG_INSTROOT}/etc/init.d/tailscale.luci $${IPKG_INSTROOT}/etc/init.d/tailscale
fi
if [[ -f $${IPKG_INSTROOT}/etc/config/tailscale.luci ]]; then
	mv $${IPKG_INSTROOT}/etc/config/tailscale.luci $${IPKG_INSTROOT}/etc/config/tailscale
fi
if [[ -z "$${IPKG_INSTROOT}" ]]; then
	if [[ -f /etc/uci-defaults/40_luci-tailscale ]]; then
		( . /etc/uci-defaults/40_luci-tailscale ) && rm -f /etc/uci-defaults/40_luci-tailscale
	fi
	rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
fi
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature