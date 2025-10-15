include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=fbtft-gc9107
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/fbtft-gc9107
  SUBMENU:=Video Support
  TITLE:=GC9107 Framebuffer Driver
  DEPENDS:=@TARGET_msm89xx +kmod-backlight
  KCONFIG:= \
    CONFIG_FB=y \
    CONFIG_FB_BACKLIGHT=y \
    CONFIG_FB_DEFERRED_IO=y \
    CONFIG_FB_SYS_FILLRECT=y \
    CONFIG_FB_SYS_COPYAREA=y \
    CONFIG_FB_SYS_IMAGEBLIT=y \
    CONFIG_FB_SYS_FOPS=y \
    CONFIG_FB_DMAMEM_HELPERS=y \
    CONFIG_BACKLIGHT_CLASS_DEVICE=y \
    CONFIG_BACKLIGHT_PWM=y \
    CONFIG_FONTS=y \
    CONFIG_FONT_8x16=y \
    CONFIG_FRAMEBUFFER_CONSOLE=y \
    CONFIG_FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER=n \
    CONFIG_VT_HW_CONSOLE_BINDING=y \
    CONFIG_VT_CONSOLE_SLEEP=y \
    CONFIG_STAGING=y \
    CONFIG_FB_TFT=y \
    CONFIG_FB_TFT_GC9107=y
  FILES:= \
    $(LINUX_DIR)/drivers/staging/fbtft/fbtft.ko \
    $(LINUX_DIR)/drivers/staging/fbtft/fb_gc9107.ko
  AUTOLOAD:=$(call AutoProbe,fbtft fb_gc9107)
endef

define KernelPackage/fbtft-gc9107/description
  GC9107 framebuffer driver for MF68E device with boot logo support.
endef

define Build/Compile
endef

define KernelPackage/fbtft-gc9107/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/lib/preinit
	
	$(INSTALL_DATA) ./files/boot_logo.fb $(1)/etc/boot_logo.fb
	$(INSTALL_BIN) ./files/05_display_logo $(1)/lib/preinit/05_display_logo
endef

$(eval $(call KernelPackage,fbtft-gc9107))
