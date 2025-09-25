#
# Copyright (C) 2020-2022 HandsomeMod Project
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qcom-firmware
PKG_VERSION:=1034.2.2
PKG_RELEASE:=2

PKG_MAINTAINER:=hkfuertes
STRIP:=:

include $(INCLUDE_DIR)/package.mk

define Package/qcom-firmware-default
  SECTION:=firmware
  CATEGORY:=Firmware
endef

define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/uz801
	mcopy -i ./files/uz801/modem.bin -p -m -n -v \
		::image/mba.mbn ::image/modem.* ::image/wcnss.* \
		::image/modem_pr/mcfg/configs/mcfg_sw/generic/common/default/default/mcfg_sw.mbn $(PKG_BUILD_DIR)/uz801
	debugfs -R "dump WCNSS_qcom_wlan_nv.bin $(PKG_BUILD_DIR)/uz801/WCNSS_qcom_wlan_nv.bin" ./files/uz801/persist.bin
endef

define Package/qcom-msm8916-uz801-wcnss-firmware
  $(Package/qcom-firmware-default)
  TITLE:=UZ801 WIFI & Bluetooth firmware
endef

define Package/qcom-msm8916-wcnss-uz801-nv
  $(Package/qcom-firmware-default)
  TITLE:=Qualcomm msm8916 WIFI nv data for UZ801
endef

define Package/qcom-msm8916-modem-uz801-firmware
  $(Package/qcom-firmware-default)
  TITLE:=Qualcomm msm8916 modem firmware for UZ801
endef

define Package/qcom-msm8916-uz801-wcnss-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/uz801/wcnss.* \
		$(1)/lib/firmware
endef

define Package/qcom-msm8916-wcnss-uz801-nv/install
	$(INSTALL_DIR) $(1)/lib/firmware/wlan/prima
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/uz801/WCNSS_qcom_wlan_nv.bin \
		$(1)/lib/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin
endef

define Package/qcom-msm8916-modem-uz801-firmware/install
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

$(eval $(call BuildPackage,qcom-msm8916-uz801-wcnss-firmware))
$(eval $(call BuildPackage,qcom-msm8916-wcnss-uz801-nv))
$(eval $(call BuildPackage,qcom-msm8916-modem-uz801-firmware))
