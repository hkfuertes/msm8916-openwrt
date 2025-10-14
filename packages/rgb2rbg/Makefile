include $(TOPDIR)/rules.mk

PKG_NAME:=rgb2rbg
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/rgb2rbg
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=RGB565 to RBG converter
endef

define Package/rgb2rbg/description
  Converts RGB565 to RBG (swaps Green and Blue channels).
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		-O3 -fomit-frame-pointer -funroll-loops \
		-o $(PKG_BUILD_DIR)/rgb2rbg \
		$(PKG_BUILD_DIR)/rgb2rbg.c
	# $(TARGET_STRIP) $(PKG_BUILD_DIR)/rgb2rbg
endef

define Build/Install
endef

define Package/rgb2rbg/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rgb2rbg $(1)/usr/bin/
endef

$(eval $(call BuildPackage,rgb2rbg))
