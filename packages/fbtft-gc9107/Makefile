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
    CONFIG_STAGING=y \
    CONFIG_FB_TFT=m \
    CONFIG_FB_TFT_GC9107=m
  FILES:= \
    $(LINUX_DIR)/drivers/staging/fbtft/fbtft.ko \
    $(LINUX_DIR)/drivers/staging/fbtft/fb_gc9107.ko
  AUTOLOAD:=$(call AutoProbe,fbtft fb_gc9107)
endef

define KernelPackage/fbtft-gc9107/description
  GC9107 framebuffer driver for MF68E device.
endef

define Build/Compile
endef

$(eval $(call KernelPackage,fbtft-gc9107))
