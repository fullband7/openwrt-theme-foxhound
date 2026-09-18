#!/bin/sh

REPO_API="https://api.github.com/repos/fullband7/openwrt-theme-foxhound/releases/latest"
TMP="/tmp/luci-theme-foxhound"

echo -e "\033[38;2;38;147;255mFoxHound Theme Installer\033[0m"

get_asset_url() {
  wget -qO- "$REPO_API" 2>/dev/null \
    | sed -n "s|.*\"browser_download_url\": *\"\([^\"]*\.$1\)\".*|\1|p" \
    | head -n 1
}

download_asset() {
  ext="$1"
  url="$(get_asset_url "$ext")"

  if [ -z "$url" ]; then
    echo -e "\033[1;31mError: No .${ext} file found in the latest release!\033[0m"
    exit 1
  fi

  echo "Downloading: $url"
  wget -O "${TMP}.${ext}" "$url" || {
    echo -e "\033[1;31mError: Download failed!\033[0m"
    rm -f "${TMP}.${ext}"
    exit 1
  }
}

if command -v apk >/dev/null 2>&1; then
  echo "Detected: apk (OpenWrt 25.12)"
  download_asset apk
  apk add --allow-untrusted "${TMP}.apk"
  rm -f "${TMP}.apk"
elif command -v opkg >/dev/null 2>&1; then
  echo "Detected: opkg (OpenWrt 24.10)"
  download_asset ipk
  opkg install "${TMP}.ipk"
  rm -f "${TMP}.ipk"
else
  echo -e "\033[1;31mError: Neither apk nor opkg found!\033[0m"
  exit 1
fi

chmod 0755 /usr/libexec/rpcd/foxhound 2>/dev/null
uci set luci.main.mediaurlbase=/luci-static/foxhound
uci commit luci
rm -f /tmp/luci-indexcache.* 2>/dev/null
rm -rf /tmp/luci-modulecache/ 2>/dev/null
[ -x /etc/init.d/rpcd ] && /etc/init.d/rpcd restart 2>/dev/null

echo ""
echo -e "\033[1;32mFoxHound Theme Installed Successfully!\033[0m"
