include $(TOPDIR)/rules.mk

PKG_NAME:=msm-firmware-loader
PKG_VERSION:=1.0
PKG_RELEASE:=1

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
endef

define Build/Configure
endef

define Build/Compile
	@echo "" >> $(PKG_BUILD_DIR)/msm-firmware-loader.sh
	@echo "# Custom remoteproc restart after firmware path is set:" >> $(PKG_BUILD_DIR)/msm-firmware-loader.sh
	cat ./files/remoteproc-restart-extra.addon >> $(PKG_BUILD_DIR)/msm-firmware-loader.sh
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/msm-firmware-loader.init $(1)/etc/init.d/msm-firmware-loader
	
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/msm-firmware-loader.sh $(1)/usr/sbin/msm-firmware-loader
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
