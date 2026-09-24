include $(TOPDIR)/rules.mk

LUCI_TITLE:=FoxHound Theme
LUCI_DESCRIPTION:=FoxHound is a dashboard-focused theme for the LuCI web interface.
LUCI_DEPENDS:=+luci-base +jsonfilter

PKG_VERSION:=2.2.4
PKG_RELEASE:=4

PKG_MAINTAINER:=FoxHound Theme
PKG_LICENSE:=Apache-2.0

CONFIG_LUCI_CSSTIDY:=

define Package/luci-theme-foxhound/conffiles
/etc/config/foxhound
endef

define Package/luci-theme-foxhound/postinst
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || [ -n "${APK_INSTROOT}" ] && exit 0

uci set luci.main.mediaurlbase=/luci-static/foxhound
uci commit luci

chmod 0755 /usr/libexec/rpcd/foxhound 2>/dev/null
chmod 0755 /etc/uci-defaults/30_luci-theme-foxhound 2>/dev/null

rm -f /tmp/luci-indexcache /tmp/luci-indexcache.*
rm -rf /tmp/luci-modulecache/

[ -x /etc/init.d/rpcd ] && /etc/init.d/rpcd restart 2>/dev/null

exit 0
endef

define Package/luci-theme-foxhound/postrm
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || [ -n "${APK_INSTROOT}" ] && exit 0

CURRENT_THEME=$$(uci -q get luci.main.mediaurlbase)

[ "$$CURRENT_THEME" = "/luci-static/foxhound" ] && {
	uci set luci.main.mediaurlbase=/luci-static/bootstrap
	uci commit luci
}

uci -q delete foxhound.settings
uci -q commit foxhound

rm -rf /www/luci-static/foxhound
rm -rf /tmp/foxhound
rm -f /tmp/luci-indexcache /tmp/luci-indexcache.*
rm -rf /tmp/luci-modulecache/

[ -x /etc/init.d/rpcd ] && /etc/init.d/rpcd restart 2>/dev/null

exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk
# call BuildPackage - OpenWrt buildroot signature
