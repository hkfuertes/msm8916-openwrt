include $(TOPDIR)/rules.mk

PKG_NAME:=msm8916-usb-gadget
PKG_VERSION:=1.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=Utilities
	CATEGORY:=Utilities
	TITLE:=USB Gadget with config for msm8916 chipsets
	DEPENDS:=@USB_GADGET_SUPPORT +kmod-fs-configfs +kmod-usb-gadget +kmod-usb-lib-composite +kmod-usb-gadget-serial +kmod-usb-gadget-mass-storage +kmod-usb-gadget-ncm +coreutils-truncate +coreutils-shuf +coreutils-dd
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) ./files/msm8916-usb-gadget.conf $(1)/etc/

	# Script principal (llamado por init.d)
	$(INSTALL_BIN) ./files/msm8916-usb-gadget.sh $(1)/etc/msm8916-usb-gadget.sh

	# Wrapper init.d (procd, rc.common)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/msm8916-usb-gadget.init $(1)/etc/init.d/msm8916-usb-gadget
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
