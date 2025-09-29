include $(TOPDIR)/rules.mk

PKG_NAME:=msm-firmware-loader
PKG_VERSION:=1.0
PKG_RELEASE:=2

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://gitlab.postmarketos.org/postmarketOS/msm-firmware-loader
PKG_SOURCE_VERSION:=0ee065ac2a507504c9606150a8ef67f43ab3f364

PKG_LICENSE:=BSD-3-Clause

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Loads firmware blobs from firmware partitions on qcom devices.
	DEPENDS:=+bash +kmod-fs-ext4 +e2fsprogs +kmod-fs-vfat +kmod-nls-cp437 +kmod-nls-iso8859-1
endef

define Build/Configure
endef

define Build/Compile
    # Suppress dirname error by redirecting stderr
    sed -i 's|xargs dirname|xargs dirname 2>/dev/null || echo ""|' $(PKG_BUILD_DIR)/msm-firmware-loader.sh
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/msm-firmware-loader.init $(1)/etc/init.d/msm-firmware-loader
	
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/msm-firmware-loader.sh $(1)/usr/sbin/msm-firmware-loader
	$(INSTALL_BIN) ./files/msm-firmware-post.sh $(1)/usr/sbin/msm-firmware-post
	
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_BIN) ./files/mcfg_sw.mbn $(1)/lib/firmware/MCFG_SW.MBN
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
