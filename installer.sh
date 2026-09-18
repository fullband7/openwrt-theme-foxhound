#!/bin/sh

REPO="https://github.com/fullband7/openwrt-theme-foxhound/releases/latest/download"
TMP="/tmp/luci-theme-foxhound"

echo -e "\033[38;2;38;147;255mFoxHound Theme Installer\033[0m"

if command -v apk >/dev/null 2>&1; then
  echo "Detected: apk (OpenWrt 25.12)"
  wget -O "${TMP}.apk" "${REPO}/luci-theme-foxhound.apk"
  apk add --allow-untrusted "${TMP}.apk"
  rm -f "${TMP}.apk"
elif command -v opkg >/dev/null 2>&1; then
  echo "Detected: opkg (OpenWrt 24.10)"
  wget -O "${TMP}.ipk" "${REPO}/luci-theme-foxhound.ipk"
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
echo -e "\033[1;32mFoxHound theme installed successfully!\033[0m"