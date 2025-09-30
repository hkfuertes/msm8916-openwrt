include $(TOPDIR)/rules.mk

PKG_NAME:=simple-serial-gadget
PKG_VERSION:=1.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    SECTION:=utils
    CATEGORY:=Utilities
    TITLE:=Simple USB ACM Serial for debugging
    DEPENDS:=@USB_GADGET_SUPPORT +kmod-usb-gadget-serial
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/simple-serial-gadget.init $(1)/etc/init.d/simple-serial-gadget
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
