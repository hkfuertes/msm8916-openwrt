include $(TOPDIR)/rules.mk

PKG_NAME:=rootfs-resizer
PKG_VERSION:=1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Resize rootfs (ext4 only)
  DEPENDS:=+resize2fs +mount-utils +e2fsprogs +tune2fs
endef

define Package/$(PKG_NAME)/description
  Automatically resize ext4 rootfs on first boot
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/rootfs-resizer.init $(1)/etc/init.d/rootfs-resizer
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/rootfs-resizer.sh $(1)/usr/bin/rootfs-resizer
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
