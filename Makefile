include $(TOPDIR)/rules.mk

PKG_NAME:=luci-theme-foxhound
PKG_VERSION:=2.0
PKG_RELEASE:=5

PKG_MAINTAINER:=FoxHound Theme
PKG_LICENSE:=Apache-2.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Themes
  TITLE:=FoxHound theme for LuCI
  PKGARCH:=all
  DEPENDS:=+luci-base
  # CONFLICTS:=luci-theme-foxhound-legacy
endef

define Package/$(PKG_NAME)/description
  FoxHound is a dashboard-focused theme for the LuCI web interface.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/foxhound
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./luci-theme-foxhound/etc/config/foxhound $(1)/etc/config/foxhound

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./luci-theme-foxhound/etc/uci-defaults/30_luci-theme-foxhound $(1)/etc/uci-defaults/30_luci-theme-foxhound

	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./luci-theme-foxhound/usr/libexec/rpcd/foxhound $(1)/usr/libexec/rpcd/foxhound

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./luci-theme-foxhound/usr/share/luci/menu.d/luci-theme-foxhound.json $(1)/usr/share/luci/menu.d/luci-theme-foxhound.json

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./luci-theme-foxhound/usr/share/rpcd/acl.d/luci-theme-foxhound.json $(1)/usr/share/rpcd/acl.d/luci-theme-foxhound.json

	$(INSTALL_DIR) $(1)/usr/share/ucode/luci/template/foxhound
	$(CP) ./luci-theme-foxhound/usr/share/ucode/luci/template/foxhound/. $(1)/usr/share/ucode/luci/template/foxhound/

	$(INSTALL_DIR) $(1)/usr/share/ucode/luci/template/themes/foxhound
	$(CP) ./luci-theme-foxhound/usr/share/ucode/luci/template/themes/foxhound/. $(1)/usr/share/ucode/luci/template/themes/foxhound/

	$(INSTALL_DIR) $(1)/www/luci-static
	$(CP) ./luci-theme-foxhound/www/luci-static/foxhound $(1)/www/luci-static/

	$(INSTALL_DIR) $(1)/www/luci-static/resources
	$(CP) ./luci-theme-foxhound/www/luci-static/resources/. $(1)/www/luci-static/resources/
endef

define Package/$(PKG_NAME)/postinst
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

define Package/$(PKG_NAME)/postrm
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

$(eval $(call BuildPackage,$(PKG_NAME)))
