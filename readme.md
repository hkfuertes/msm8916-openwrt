## WRT for uz801
These are my attempts at building the os... my end goal is to build a working modern openwrt, but first I will start from immortalwrt from lkiuyu and the from official immortalwrt.

### lkiuyu/immortalwrt
- Modem Working
  - No Rx/Tx displayed in luci interface (?)
- Wifi Working
- USB gadget working (NCM, RNDIS, MASS, ACM tested!)
---
### TODO:
- Recover GHA build pipeline
- Use built dtb from openstick-builder?
  - use linux's dts?
- modemmanager not showing rxtx
- Use mcopy and debugfs compiled by openwrt:
    ```makefile
      include $(TOPDIR)/rules.mk

      PKG_NAME:=foo
      PKG_RELEASE:=1
      PKG_BUILD_DEPENDS:=mtools/host

      include $(INCLUDE_DIR)/package.mk

      define Package/foo
        SECTION:=utils
        CATEGORY:=Utilities
        TITLE:=Foo example using mcopy
      endef

      # Ejemplo: crear/usar una imagen FAT en tiempo de build
      define Build/Compile
        # crea directorio dentro de la imagen
        $(STAGING_DIR_HOST)/bin/mmd   -i $(PKG_BUILD_DIR)/fs.img ::/etc
        # copia un archivo a la imagen sin usar mcopy del sistema
        $(STAGING_DIR_HOST)/bin/mcopy -i $(PKG_BUILD_DIR)/fs.img $(PKG_BUILD_DIR)/my.conf ::/etc/my.conf
      endef

      define Package/foo/install
        $(INSTALL_DIR) $(1)/usr/share/foo
        $(INSTALL_DATA) $(PKG_BUILD_DIR)/fs.img $(1)/usr/share/foo/
      endef

      $(eval $(call BuildPackage,foo))
    ```
---
### Stuff
- The `msm8916-yiming-uz801v3.dtb` file is a prebuilt dtb extracted from one of the many OpenStick-Builder project living in Github.