include $(TOPDIR)/rules.mk

PKG_NAME:=router-display
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_QRGEN_NAME:=QR-Code-generator
PKG_QRGEN_VERSION:=v1.8.0
PKG_QRGEN_SOURCE:=$(PKG_QRGEN_VERSION).tar.gz
PKG_QRGEN_URL:=https://github.com/nayuki/QR-Code-generator/archive/refs/tags
PKG_QRGEN_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/router-display
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Framebuffer router status display
  DEPENDS:=+libfreetype +kmod-button-hotplug +dejavu-fonts-ttf-DejaVuSans-Bold +dejavu-fonts-ttf-DejaVuSans
endef

define Package/router-display/description
  Display router status on RGB565 framebuffer
endef

define Download/qrcodegen
  URL:=$(PKG_QRGEN_URL)
  FILE:=qrcodegen-$(PKG_QRGEN_VERSION).tar.gz
  URL_FILE:=$(PKG_QRGEN_VERSION).tar.gz
  HASH:=$(PKG_QRGEN_HASH)
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/main.c $(PKG_BUILD_DIR)/
	$(eval $(call Download,qrcodegen))
	tar -xzf $(DL_DIR)/qrcodegen-$(PKG_QRGEN_VERSION).tar.gz -C $(PKG_BUILD_DIR)
	$(CP) $(PKG_BUILD_DIR)/$(PKG_QRGEN_NAME)-*/c/qrcodegen.c $(PKG_BUILD_DIR)/
	$(CP) $(PKG_BUILD_DIR)/$(PKG_QRGEN_NAME)-*/c/qrcodegen.h $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) -O3 -ffast-math \
		$(TARGET_CPPFLAGS) \
		-I$(STAGING_DIR)/usr/include/freetype2 \
		$(TARGET_LDFLAGS) \
		-o $(PKG_BUILD_DIR)/router-display \
		$(PKG_BUILD_DIR)/main.c \
		$(PKG_BUILD_DIR)/qrcodegen.c \
		-lfreetype -lm
endef

define Package/router-display/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/router-display $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/update-display.sh $(1)/usr/sbin/update-display

	$(INSTALL_DIR) $(1)/etc/hotplug.d/button
	$(INSTALL_BIN) ./files/hotplugs/20_power_dimm $(1)/etc/hotplug.d/button/20_power_dimm
	$(INSTALL_BIN) ./files/hotplugs/30_power_update $(1)/etc/hotplug.d/button/30_power_update
endef

$(eval $(call BuildPackage,router-display))
