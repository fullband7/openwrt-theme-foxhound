#
# Copyright (C) 2026 fullband7
#
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-theme-foxhound
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=fullband7

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/fullband7/openwrt-theme-foxhound.git
PKG_SOURCE_DATE:=2026-09-05
PKG_SOURCE_VERSION:=29ae1be8ad5294bb9d3e95bec5a1f99fc2cff8b5
PKG_MIRROR_HASH:=skip

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/luci-theme-foxhound
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Themes
  TITLE:=FoxHound - Modern and clean LuCI theme for OpenWrt
  PKGARCH:=all
  DEPENDS:=+lua +libc +libuci-lua +luci-compat +luci-lib-jsonc +luci-lua-runtime
endef

define Package/luci-theme-foxhound/description
  FoxHound is a modern and clean LuCI theme for OpenWrt, providing a
  refreshed interface built on ucode templates.
endef

define Build/Compile
endef

define Package/luci-theme-foxhound/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/foxhound
	$(CP) $(PKG_BUILD_DIR)/luci-theme-foxhound/controller/. $(1)/usr/lib/lua/luci/controller/foxhound/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/foxhound
	$(CP) $(PKG_BUILD_DIR)/luci-theme-foxhound/view/. $(1)/usr/lib/lua/luci/view/foxhound/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luci-theme-foxhound/etc/config/foxhound $(1)/etc/config/foxhound

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/luci-theme-foxhound/etc/uci-defaults/30_luci-theme-foxhound $(1)/etc/uci-defaults/

	$(INSTALL_DIR) $(1)/usr/share/ucode/luci/template/themes/foxhound
	$(CP) $(PKG_BUILD_DIR)/luci-theme-foxhound/ucode/. $(1)/usr/share/ucode/luci/template/themes/foxhound/

	$(INSTALL_DIR) $(1)/www/luci-static
	$(CP) $(PKG_BUILD_DIR)/luci-theme-foxhound/luci-static/. $(1)/www/luci-static/

	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/luci-theme-foxhound/usr/libexec/rpcd/foxhound $(1)/usr/libexec/rpcd/foxhound

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luci-theme-foxhound/usr/share/rpcd/acl.d/luci-theme-foxhound.json $(1)/usr/share/rpcd/acl.d/luci-theme-foxhound.json
endef

define Package/luci-theme-foxhound/preinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ] && [ -z "$${APK_INSTROOT}" ]; then
    if [ -x "$$(which apk 2>/dev/null)" ]; then
        apk del luci-theme-foxhound 2>/dev/null || true
    else
        opkg remove luci-theme-foxhound 2>/dev/null || true
    fi
fi
exit 0
endef

define Package/luci-theme-foxhound/postinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ] && [ -z "$${APK_INSTROOT}" ]; then
    rm -f /tmp/luci-indexcache.* 2>/dev/null
    rm -rf /tmp/luci-modulecache/ 2>/dev/null
    uci set luci.main.mediaurlbase=/luci-static/foxhound
    uci commit luci
    chmod +x /usr/libexec/rpcd/foxhound
    if [ -x /etc/init.d/rpcd ]; then
        /etc/init.d/rpcd restart 2>/dev/null || true
    fi
fi
exit 0
endef

define Package/luci-theme-foxhound/postrm
#!/bin/sh

[ -n "$${IPKG_INSTROOT}" ] && exit 0
[ -n "$${APK_INSTROOT}" ]  && exit 0

CURRENT_THEME=$$(uci get luci.main.mediaurlbase 2>/dev/null)
if [ "$$CURRENT_THEME" = "/luci-static/foxhound" ]; then
    uci set luci.main.mediaurlbase="/luci-static/bootstrap"
    uci commit luci
fi

uci -q delete foxhound.settings
uci -q commit foxhound

rm -rf /www/luci-static/foxhound
rm -rf /tmp/foxhound
rm -f  /tmp/luci-indexcache.*
rm -rf /tmp/luci-modulecache/

/etc/init.d/rpcd restart 2>/dev/null

exit 0
endef

$(eval $(call BuildPackage,luci-theme-foxhound))