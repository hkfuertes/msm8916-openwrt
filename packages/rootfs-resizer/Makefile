include $(TOPDIR)/rules.mk

PKG_NAME:=rootfs-resizer
PKG_VERSION:=1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=Utilities
  CATEGORY:=Utilities
  TITLE:=Resize Rootfs (ext4 fs only)
  DEPENDS:=+resize2fs +mount-utils +e2fsprogs +tune2fs
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/rootfs-resizer.init $(1)/etc/init.d/rootfs-resizer
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
