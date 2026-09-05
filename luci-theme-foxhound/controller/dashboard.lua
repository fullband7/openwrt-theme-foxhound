module("luci.controller.foxhound.dashboard", package.seeall)
local function foxhound_theme_active()
 local uci = require "luci.model.uci".cursor()
 return uci:get("luci", "main", "mediaurlbase") == "/luci-static/foxhound"
end
function index()
 if not foxhound_theme_active() then
  return
 end
 entry({"admin"}, call("action_dashboard"), _("Dashboard"), 1)
 entry({"admin", "dashboard"}, call("action_dashboard"), _("Dashboard"), 1)
end
function action_dashboard()
 luci.template.render("foxhound/dashboard", {
  hostname = luci.sys.hostname(),
  uptime = luci.sys.uptime(),
  firmware = luci.sys.exec(". /etc/openwrt_release 2>/dev/null && echo $DISTRIB_DESCRIPTION") or "OpenWrt"
 })
end
