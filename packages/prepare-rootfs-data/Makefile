# package/system/prepare-rootfs-data/Makefile

include $(TOPDIR)/rules.mk

PKG_NAME:=prepare-rootfs-data
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/prepare-rootfs-data
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Automatically format rootfs_data on first boot
  DEPENDS:=@TARGET_ROOTFS_SQUASHFS +e2fsprogs +blkid
  PKGARCH:=all
endef

define Package/prepare-rootfs-data/description
  Preinit script that automatically formats the rootfs_data partition
  with ext4 filesystem if it is empty or unformatted, enabling overlay
  filesystem to work without manual intervention.
endef

define Build/Compile
endef

define Package/prepare-rootfs-data/install
	$(INSTALL_DIR) $(1)/lib/preinit
	$(INSTALL_BIN) ./files/79-format-rootfs-data $(1)/lib/preinit/79-format-rootfs-data
endef

$(eval $(call BuildPackage,prepare-rootfs-data))
