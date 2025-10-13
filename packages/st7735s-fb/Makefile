#
# ST7735S Framebuffer Driver for OpenWRT/MSM8916
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=st7735s-fb
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/st7735s-fb
  SUBMENU:=Video Support
  TITLE:=ST7735S Framebuffer Driver
  DEPENDS:=+kmod-fb +kmod-fb-sys-fops
  KCONFIG:= \
	CONFIG_FB=y \
	CONFIG_FB_SYS_FILLRECT=y \
	CONFIG_FB_SYS_COPYAREA=y \
	CONFIG_FB_SYS_IMAGEBLIT=y \
	CONFIG_FB_SYS_FOPS=y \
	CONFIG_FB_DEFERRED_IO=y
  FILES:=$(PKG_BUILD_DIR)/st7735s.ko
  AUTOLOAD:=$(call AutoProbe,st7735s)
endef

define KernelPackage/st7735s-fb/description
  Framebuffer driver for Sitronix ST7735S display controller.
  Optimized for MSM8916 with Android 4.4 initialization sequence.
  
  Features:
  - 128x128 @ 16bpp RGB565
  - SPI interface (16MHz)
  - GPIO reset and DC control
  - Deferred I/O for efficiency
  
  Device: /dev/fb0
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(KERNEL_MAKE_FLAGS) \
		M="$(PKG_BUILD_DIR)" \
		modules
endef

define KernelPackage/st7735s-fb/install
	$(INSTALL_DIR) $(1)/etc/modules.d
	echo "st7735s" > $(1)/etc/modules.d/60-st7735s
endef

$(eval $(call KernelPackage,st7735s-fb))
