# Maintainer: fullband7
# Contributor: FullBand
pkgname=luci-theme-foxhound
pkgver=
pkgrel=0
pkgdesc="FoxHound - Modern and clean LuCI theme for OpenWrt"
url="https://github.com/fullband7/openwrt-theme-foxhound"
arch="noarch"
license="Apache-2.0"
depends="lua libc libuci-lua luci-compat luci-lib-jsonc luci-lua-runtime"
source=""
sha512sums=""
builddir="$startdir"

package() {
	cd "$builddir"

	mkdir -p "$pkgdir"/usr/lib/lua/luci/controller
	cp -a controller/. "$pkgdir"/usr/lib/lua/luci/controller/ 2>/dev/null || true

	mkdir -p "$pkgdir"/usr/lib/lua/luci/view/dashboard
	cp -a view/. "$pkgdir"/usr/lib/lua/luci/view/dashboard/ 2>/dev/null || true

	mkdir -p "$pkgdir"/usr/share/ucode/luci/template/themes/foxhound
	cp -a "ucode"/. "$pkgdir"/usr/share/ucode/luci/template/themes/foxhound/ 2>/dev/null || true

	mkdir -p "$pkgdir"/www/luci-static/
    cp -a luci-static/. "$pkgdir"/www/luci-static/ 2>/dev/null || true

	find "$pkgdir" -type f -exec chmod 644 {} +
	find "$pkgdir" -type d -exec chmod 755 {} +
}
