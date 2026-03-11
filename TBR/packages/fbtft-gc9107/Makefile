include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

PKG_NAME:=fbtft-gc9107
PKG_RELEASE:=1

define KernelPackage/fbtft-gc9107
  SUBMENU:=Video Support
  TITLE:=GC9107 Framebuffer Driver (fbtft)
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
  GC9107 framebuffer driver (fbtft) for MSM8916-based devices (MF68E/UZ801).
  Includes deferred I/O, sys_* helpers, PWM backlight and fbcon.
endef

define Build/Compile
endef

define KernelPackage/fbtft-gc9107/install
	$(INSTALL_DIR) $(1)/lib/preinit
	$(INSTALL_BIN) ./preinit/05_dim_backlight $(1)/lib/preinit/05_dim_backlight
endef

$(eval $(call KernelPackage,fbtft-gc9107))
