include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=fbtft-st7735
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/fbtft-st7735
  SUBMENU:=Video Support
  TITLE:=ST7735R/S Framebuffer Driver (Custom for MF68E)
  DEPENDS:=@TARGET_msm89xx
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
    CONFIG_FB_TFT_ST7735R=m
  FILES:= \
    $(LINUX_DIR)/drivers/staging/fbtft/fbtft.ko \
    $(LINUX_DIR)/drivers/staging/fbtft/fb_st7735r.ko
  AUTOLOAD:=$(call AutoProbe,fbtft fb_st7735r)
endef

define KernelPackage/fbtft-st7735/description
  Custom ST7735R/S framebuffer driver for MF68E device.
  Includes proper initialization sequence from Android kernel.
endef

define Build/Compile
endef

$(eval $(call KernelPackage,fbtft-st7735))
