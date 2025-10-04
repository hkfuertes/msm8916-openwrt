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
	mkdir -p $(PKG_BUILD_DIR)
	mcopy -i ./files/modem.bin -p -m -n -v \
		::image/mba.mbn ::image/modem.* ::image/wcnss.* \
		::image/modem_pr/mcfg/configs/mcfg_sw/generic/common/default/default/mcfg_sw.mbn $(PKG_BUILD_DIR)
	debugfs -R "dump WCNSS_qcom_wlan_nv.bin $(PKG_BUILD_DIR)/WCNSS_qcom_wlan_nv.bin" ./files/persist.bin
endef

define Package/msm8916-wcnss-firmware
  $(Package/firmware-default)
  TITLE:=MSM8916 WIFI & Bluetooth firmware
endef

define Package/msm8916-wcnss-nv
  $(Package/firmware-default)
  TITLE:=Qualcomm msm8916 WIFI nv data
endef

define Package/msm8916-modem-firmware
  $(Package/firmware-default)
  TITLE:=Qualcomm msm8916 modem firmware
endef

define Package/msm8916-wcnss-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/wcnss.* \
		$(1)/lib/firmware
endef

define Package/msm8916-wcnss-nv/install
	$(INSTALL_DIR) $(1)/lib/firmware/wlan/prima
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/WCNSS_qcom_wlan_nv.bin \
		$(1)/lib/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin
endef

define Package/msm8916-modem-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/mba.mbn \
		$(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/modem.* \
		$(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/mcfg_sw.mbn \
		$(1)/lib/firmware/MCFG_SW.MBN
endef

$(eval $(call BuildPackage,msm8916-wcnss-firmware))
$(eval $(call BuildPackage,msm8916-wcnss-nv))
$(eval $(call BuildPackage,msm8916-modem-firmware))
