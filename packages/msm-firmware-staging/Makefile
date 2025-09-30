include $(TOPDIR)/rules.mk

PKG_NAME:=msm-firmware-staging
PKG_VERSION:=1.1
PKG_RELEASE:=1
PKG_LICENSE:=BSD-3-Clause

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Preinit firmware staging for Qualcomm (msm/wcnss) via /run
  DEPENDS:=+kmod-fs-vfat +kmod-fs-ext4 +kmod-nls-cp437 +kmod-nls-iso8859-1
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/lib/preinit
	$(INSTALL_BIN) ./files/30-msm-firmware-stage.sh $(1)/lib/preinit/30-msm-firmware-stage.sh

	$(INSTALL_DIR) $(1)/etc/modules-boot.d
	echo vfat >  $(1)/etc/modules-boot.d/50-fs-qcom
	echo nls_cp437 >> $(1)/etc/modules-boot.d/50-fs-qcom
	echo nls_iso8859_1 >> $(1)/etc/modules-boot.d/50-fs-qcom
	echo ext4 >> $(1)/etc/modules-boot.d/50-fs-qcom

	# Opcional: perfil por defecto, si procede
	# $(INSTALL_DIR) $(1)/lib/firmware
	# $(INSTALL_DATA) ./files/MCFG_SW.MBN $(1)/lib/firmware/MCFG_SW.MBN
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
