#!/bin/sh

REPO_API="https://api.github.com/repos/fullband7/openwrt-theme-foxhound/releases/latest"
URL_PREFIX="https://github.com/fullband7/openwrt-theme-foxhound/releases/download/"

say() {
	printf '\033[%sm%s\033[0m\n' "$1" "$2"
}

fail() {
	say "1;31" "Error: $1"
	exit 1
}

[ "$(id -u)" = "0" ] || fail "This installer must be run as root."

TMP_DIR=$(mktemp -d /tmp/foxhound-install.XXXXXX) || fail "Cannot create a temporary directory."
trap 'rm -rf "$TMP_DIR"' EXIT
trap 'exit 1' INT TERM HUP

say "38;2;38;147;255" "FoxHound Theme Installer"

RELEASE=$(wget -qO- "$REPO_API" 2>/dev/null)
[ -n "$RELEASE" ] || fail "Cannot reach the GitHub API. Check your internet connection and HTTPS support."

download_asset() {
	ext="$1"
	url=$(printf '%s' "$RELEASE" | jsonfilter -e '@.assets[*].browser_download_url' 2>/dev/null | grep "\\.$ext\$" | head -n 1)

	[ -n "$url" ] || fail "No .${ext} file found in the latest release!"

	case "$url" in
		"$URL_PREFIX"?*) ;;
		*) fail "The release file is not hosted in the official repository." ;;
	esac

	PKG_FILE="$TMP_DIR/luci-theme-foxhound.$ext"
	echo "Downloading: $url"
	wget -O "$PKG_FILE" "$url" && [ -s "$PKG_FILE" ] || fail "Download failed!"
}

if command -v apk >/dev/null 2>&1; then
	echo "Detected: apk (OpenWrt 25.12)"
	download_asset apk
	apk add --allow-untrusted "$PKG_FILE" || fail "Package installation failed!"
elif command -v opkg >/dev/null 2>&1; then
	echo "Detected: opkg (OpenWrt 24.10)"
	download_asset ipk
	opkg install "$PKG_FILE" || fail "Package installation failed!"
else
	fail "Neither apk nor opkg found!"
fi

chmod 0755 /usr/libexec/rpcd/foxhound 2>/dev/null
uci set luci.main.mediaurlbase=/luci-static/foxhound && uci commit luci || fail "Could not activate the theme."
rm -f /tmp/luci-indexcache /tmp/luci-indexcache.* 2>/dev/null
rm -rf /tmp/luci-modulecache/ 2>/dev/null
[ -x /etc/init.d/rpcd ] && /etc/init.d/rpcd restart 2>/dev/null

say "1;32" "FoxHound Theme Installed Successfully!"
