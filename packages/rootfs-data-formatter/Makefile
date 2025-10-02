# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=rootfs-data-formatter
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/rootfs-data-formatter
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Auto-format rootfs_data partition at boot
  DEPENDS:=+block-mount +e2fsprogs +blkid
  PKGARCH:=all
endef

define Package/rootfs-data-formatter/description
  Automatically formats the rootfs_data partition during preinit
  if it is detected as unformatted. Only applies to squashfs-based
  systems; safely ignored on ext4 systems.
endef

define Build/Compile
	# Nothing to compile, this is a script-only package
endef

define Package/rootfs-data-formatter/install
	$(INSTALL_DIR) $(1)/lib/preinit
	$(INSTALL_BIN) ./files/79_format_rootfs_data $(1)/lib/preinit/
endef

$(eval $(call BuildPackage,rootfs-data-formatter))
