#
# Copyright (C) 2020-2022 HandsomeMod Project
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=msm8916-firmware
PKG_VERSION:=1034.2.2
PKG_RELEASE:=2

PKG_MAINTAINER:=hkfuertes
STRIP:=:

include $(INCLUDE_DIR)/package.mk

define Package/firmware-default
  SECTION:=firmware
  CATEGORY:=Firmware
endef

define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/uz801
	mcopy -i ./files/uz801/modem.bin -p -m -n -v \
		::image/mba.mbn ::image/modem.* ::image/wcnss.* \
		::image/modem_pr/mcfg/configs/mcfg_sw/generic/common/default/default/mcfg_sw.mbn $(PKG_BUILD_DIR)/uz801/
	cp ./files/uz801/WCNSS_qcom_wlan_nv.bin $(PKG_BUILD_DIR)/uz801/WCNSS_qcom_wlan_nv.bin

	mkdir -p $(PKG_BUILD_DIR)/sp970
	mcopy -i ./files/sp970/modem.bin -p -m -n -v \
		::image/mba.mbn ::image/modem.* ::image/wcnss.* $(PKG_BUILD_DIR)/sp970/
	cp ./files/sp970/WCNSS_qcom_wlan_nv.bin $(PKG_BUILD_DIR)/sp970/WCNSS_qcom_wlan_nv.bin
endef

define Package/msm8916-uz801-wcnss-firmware
  $(Package/firmware-default)
  TITLE:=MSM8916 WIFI & Bluetooth firmware
endef

define Package/msm8916-sp970-wcnss-firmware
  $(Package/firmware-default)
  TITLE:=MSM8916 WIFI & Bluetooth firmware
endef

define Package/msm8916-uz801-wcnss-nv
  $(Package/firmware-default)
  TITLE:=Qualcomm msm8916 WIFI nv data (UZ801)
endef

define Package/msm8916-sp970-wcnss-nv
  $(Package/firmware-default)
  TITLE:=Qualcomm msm8916 WIFI nv data (SP970)
endef

define Package/msm8916-uz801-modem-firmware
  $(Package/firmware-default)
  TITLE:=Qualcomm msm8916 modem firmware
endef

define Package/msm8916-sp970-modem-firmware
  $(Package/firmware-default)
  TITLE:=Qualcomm msm8916 modem firmware
endef

define Package/msm8916-uz801-wcnss-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/uz801/wcnss.* \
		$(1)/lib/firmware
endef

define Package/msm8916-sp970-wcnss-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/sp970/wcnss.* \
		$(1)/lib/firmware
endef

define Package/msm8916-uz801-wcnss-nv/install
	$(INSTALL_DIR) $(1)/lib/firmware/wlan/prima
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/uz801/WCNSS_qcom_wlan_nv.bin \
		$(1)/lib/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin
endef

define Package/msm8916-sp970-wcnss-nv/install
	$(INSTALL_DIR) $(1)/lib/firmware/wlan/prima
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/sp970/WCNSS_qcom_wlan_nv.bin \
		$(1)/lib/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin
endef

define Package/msm8916-uz801-modem-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/uz801/mba.mbn \
		$(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/uz801/modem.* \
		$(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/uz801/mcfg_sw.mbn \
		$(1)/lib/firmware/MCFG_SW.MBN
endef

define Package/msm8916-sp970-modem-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/sp970/mba.mbn \
		$(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/sp970/modem.* \
		$(1)/lib/firmware
endef

$(eval $(call BuildPackage,msm8916-uz801-wcnss-firmware))
$(eval $(call BuildPackage,msm8916-uz801-wcnss-nv))
$(eval $(call BuildPackage,msm8916-uz801-modem-firmware))
$(eval $(call BuildPackage,msm8916-sp970-wcnss-firmware))
$(eval $(call BuildPackage,msm8916-sp970-wcnss-nv))
$(eval $(call BuildPackage,msm8916-sp970-modem-firmware))
