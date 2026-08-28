#
# Copyright (C) 2026 fullband7
#
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-theme-foxhound
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=fullband7 <fullband7@example.com>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/fullband7/openwrt-theme-foxhound.git
PKG_SOURCE_DATE:=2026-01-01
PKG_SOURCE_VERSION:=HEAD
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
	$(CP) $(PKG_BUILD_DIR)/luci-theme-foxhound/controller/. $(1)/usr/lib/lua/luci/controller/foxhound/ 2>/dev/null || true

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/foxhound
	$(CP) $(PKG_BUILD_DIR)/luci-theme-foxhound/view/. $(1)/usr/lib/lua/luci/view/foxhound/ 2>/dev/null || true

	$(INSTALL_DIR) $(1)/etc/config
	$(CP) $(PKG_BUILD_DIR)/luci-theme-foxhound/config/. $(1)/etc/config/ 2>/dev/null || true

	$(INSTALL_DIR) $(1)/usr/share/ucode/luci/template/themes/foxhound
	$(CP) $(PKG_BUILD_DIR)/luci-theme-foxhound/ucode/. $(1)/usr/share/ucode/luci/template/themes/foxhound/ 2>/dev/null || true

	$(INSTALL_DIR) $(1)/www/luci-static
	$(CP) $(PKG_BUILD_DIR)/luci-theme-foxhound/luci-static/. $(1)/www/luci-static/ 2>/dev/null || true

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/luci-theme-foxhound/etc/uci-defaults/30_luci-theme-foxhound $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,luci-theme-foxhound))
