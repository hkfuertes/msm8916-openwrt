# SPDX-License-Identifier: GPL-2.0-only

define KernelPackage/qcom-rproc
  SUBMENU:=$(OTHER_MENU)
  TITLE:=Qualcomm remoteproc support
  DEPENDS:=@TARGET_msm89xx
  KCONFIG:=\
    CONFIG_QCOM_MDT_LOADER \
    CONFIG_QCOM_RPROC_COMMON \
    CONFIG_QCOM_PIL_INFO
  FILES:=\
    $(LINUX_DIR)/drivers/soc/qcom/mdt_loader.ko \
    $(LINUX_DIR)/drivers/remoteproc/qcom_common.ko \
    $(LINUX_DIR)/drivers/remoteproc/qcom_pil_info.ko
  AUTOLOAD:=$(call AutoProbe,mdt_loader qcom_common qcom_pil_info)
endef

define KernelPackage/qcom-rproc/description
Support for loading remoteprocs in some Qualcomm chipsets
endef

$(eval $(call KernelPackage,qcom-rproc))

define KernelPackage/qcom-rproc-wcnss
  SUBMENU:=$(OTHER_MENU)
  TITLE:=Qualcomm WCNSS remoteproc support
  DEPENDS:=@TARGET_msm89xx +kmod-qcom-rproc
  KCONFIG:=\
    CONFIG_QCOM_WCNSS_PIL \
    CONFIG_QCOM_WCNSS_CTRL
  FILES:=\
    $(LINUX_DIR)/drivers/remoteproc/qcom_wcnss_pil.ko \
    $(LINUX_DIR)/drivers/soc/qcom/wcnss_ctrl.ko
  AUTOLOAD:=$(call AutoProbe,qcom_wcnss_pil wcnss_ctrl)
endef

define KernelPackage/qcom-rproc-wcnss/description
Firmware loading and control for the WCNSS remoteproc
endef

$(eval $(call KernelPackage,qcom-rproc-wcnss))

define KernelPackage/qcom-rproc-modem
  SUBMENU:=$(OTHER_MENU)
  TITLE:=Qualcomm modem remoteproc support
  DEPENDS:=@TARGET_msm89xx +kmod-qcom-rproc +kmod-wwan
  KCONFIG:=\
    CONFIG_QCOM_Q6V5_COMMON \
    CONFIG_QCOM_Q6V5_MSS
  FILES:=\
    $(LINUX_DIR)/drivers/remoteproc/qcom_q6v5.ko \
    $(LINUX_DIR)/drivers/remoteproc/qcom_q6v5_mss.ko
  AUTOLOAD:=$(call AutoProbe,qcom_q6v5 qcom_q6v5_mss)
endef

define KernelPackage/qcom-rproc-modem/description
Firmware loading and control for the modem remoteproc.
endef

$(eval $(call KernelPackage,qcom-rproc-modem))

define KernelPackage/rpmsg-wwan-ctrl
  SUBMENU:=$(NETWORK_DEVICES_MENU)
  TITLE:=RPMSG WWAN Control
  DEPENDS:=@LINUX_6_1||LINUX_6_6||LINUX_6_12 +kmod-wwan
  KCONFIG:=CONFIG_RPMSG_WWAN_CTRL
  FILES:=$(LINUX_DIR)/drivers/net/wwan/rpmsg_wwan_ctrl.ko
  AUTOLOAD:=$(call AutoProbe,rpmsg_wwan_ctrl)
endef

define KernelPackage/rpmsg-wwan-ctrl/description
 Driver for RPMSG WWAN Control
 This exposes all modem control ports like AT, QMI that use RPMSG
endef

$(eval $(call KernelPackage,rpmsg-wwan-ctrl))

define KernelPackage/bam-dmux
  SUBMENU:=$(NETWORK_DEVICES_MENU)
  TITLE:=Qualcomm BAM-DMUX WWAN network driver
  DEPENDS:=@TARGET_msm89xx +kmod-wwan
  KCONFIG:=CONFIG_QCOM_BAM_DMUX
  FILES:=$(LINUX_DIR)/drivers/net/wwan/qcom_bam_dmux.ko
  AUTOLOAD:=$(call AutoProbe,qcom_bam_dmux)
endef

define KernelPackage/bam-dmux/description
  Kernel modules for Qualcomm BAM-DMUX WWAN interface
endef

$(eval $(call KernelPackage,bam-dmux))

define KernelPackage/wcn36xx
  SUBMENU:=Wireless Drivers
  TITLE:=Qualcomm Atheros WCN3660/3680 support
  URL:=https://wireless.wiki.kernel.org/en/users/drivers/wcn36xx
  DEPENDS:=@TARGET_msm89xx +kmod-ath +kmod-qcom-rproc-wcnss
  FILES:=$(LINUX_DIR)/drivers/net/wireless/ath/wcn36xx/wcn36xx.ko
  AUTOLOAD:=$(call AutoProbe,wcn36xx)
endef

define KernelPackage/wcn36xx/config
  if PACKAGE_kmod-wcn36xx
    config WCN36XX_DEBUGFS
      bool "Enable WCN36XX debugfs support"
      default y if PACKAGE_MAC80211_DEBUGFS
      help
        Say Y to enable debugfs entries for the WCN36XX driver.
  endif
endef

define KernelPackage/wcn36xx/description
  This module adds support for Qualcomm Atheros WCN3660/3680
  Wireless blocks in some Qualcomm SoCs.
endef

$(eval $(call KernelPackage,wcn36xx))
