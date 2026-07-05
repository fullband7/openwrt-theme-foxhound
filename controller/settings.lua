module("luci.controller.foxhound.settings", package.seeall)
local jsonc = require "luci.jsonc"

function index()
    entry({"admin", "system", "foxhound"}, call("action_page"), _("Theme Settings"), 60).dependent = true
    entry({"admin", "system", "foxhound", "upload_main"}, call("action_upload_main"), nil).dependent = true
    entry({"admin", "system", "foxhound", "upload_login"}, call("action_upload_login"), nil).dependent = true
    entry({"admin", "system", "foxhound", "upload_bg_main"}, call("action_upload_bg_main"), nil).dependent = true
    entry({"admin", "system", "foxhound", "upload_bg_login"}, call("action_upload_bg_login"), nil).dependent = true
    entry({"admin", "system", "foxhound", "reset_main"}, call("action_reset_main"), nil).dependent = true
    entry({"admin", "system", "foxhound", "reset_login"}, call("action_reset_login"), nil).dependent = true
    entry({"admin", "system", "foxhound", "reset_bg_main"}, call("action_reset_bg_main"), nil).dependent = true
    entry({"admin", "system", "foxhound", "check"}, call("action_check"), nil).dependent = true
    entry({"admin", "system", "foxhound", "reset_bg_login"}, call("action_reset_bg_login"), nil).dependent = true
    entry({"admin", "system", "foxhound", "save_about"}, call("action_save_about"), nil).dependent = true
end

local MAX_UPLOAD = 2 * 1024 * 1024
local MAX_BG_UPLOAD = 2 * 1024 * 1024


local function valid_magic(ext, data)
    if ext == "png" then
        return data:sub(1, 4) == "\137PNG"
    elseif ext == "gif" then
        return data:sub(1, 4) == "GIF8"
    elseif ext == "jpg" or ext == "jpeg" then
        return data:sub(1, 3) == "\255\216\255"
    elseif ext == "webp" then
        return data:sub(1, 4) == "RIFF" and data:sub(9, 12) == "WEBP"
    end
    return false
end

local function safe_remove(prefix)
    local fs = require "nixio.fs"
    for _, e in ipairs({"png","jpg","jpeg","gif","webp"}) do
        local p = "/www/luci-static/foxhound/resources/upload/" .. prefix .. "." .. e
        if fs.access(p) then fs.unlink(p) end
    end
end

local function check_csrf(data_token)
    local http = require "luci.http"
    local dispatcher = require "luci.dispatcher"
    local received_token = data_token or http.formvalue("token")
    local session_token = dispatcher.context.authtoken

    if not received_token or not session_token or received_token ~= session_token then
        http.status(403, "Forbidden - CSRF Token Mismatch")
        return false
    end
    return true
end

local function save_logo(prefix, uci_key)
    local http = require "luci.http"
    local uci = require "luci.model.uci".cursor()
    local source = http.source()
    local chunks = {}
    local total = 0

    if source then
        while true do
            local chunk = source()
            if not chunk then break end
            total = total + #chunk
            if total > MAX_UPLOAD * 2 then
                http.status(413, "Payload Too Large")
                return
            end
            chunks[#chunks + 1] = chunk
        end
    end
    local json_str = table.concat(chunks)

    if json_str == "" then
        http.status(400, "Bad Request")
        return
    end
    
    local data = jsonc.parse(json_str)
    if not data or not data.file_data or not data.ext then
        http.status(400, "Invalid Data")
        return
    end
    
    if not check_csrf(data.token) then return end
    
    local ext = data.ext:lower()
    if ext ~= "png" and ext ~= "jpg" and ext ~= "jpeg" and ext ~= "gif" and ext ~= "webp" then
        http.status(400, "Invalid Format")
        return
    end
    
    local nixio = require "nixio"
    local decoded = nixio.bin.b64decode(data.file_data)
    if not decoded then
        http.status(500, "Decode Error")
        return
    end

    if #decoded > MAX_UPLOAD then
        http.status(413, "File Too Large")
        return
    end

    if not valid_magic(ext, decoded) then
        http.status(400, "File content does not match extension")
        return
    end

    safe_remove(prefix)
    
    local file_path = "/www/luci-static/foxhound/resources/upload/" .. prefix .. "." .. ext
    local fp = io.open(file_path, "wb")
    if not fp then
        http.status(500, "Write Error")
        return
    end
    
    fp:write(decoded)
    fp:close()
    
    local web_path = "/luci-static/foxhound/resources/upload/" .. prefix .. "." .. ext
    if not uci:get("foxhound", "settings") then
        uci:set("foxhound", "settings", "settings")
    end
    uci:set("foxhound", "settings", uci_key, web_path)
    uci:commit("foxhound")
    
    http.prepare_content("application/json")
    http.write('{"success":true}')
end

local function reset_logo(prefix, uci_key)

    if not check_csrf() then return end
    
    local http = require "luci.http"
    local uci = require "luci.model.uci".cursor()
    
    safe_remove(prefix)
    
    if uci_key == "login_logo_url" then
        uci:set("foxhound", "settings", uci_key, "/luci-static/foxhound/resources/icons/logo.svg")
    else
        uci:delete("foxhound", "settings", uci_key)
    end
    
    uci:commit("foxhound")
    
    http.prepare_content("application/json")
    http.write('{"success":true}')
end

function action_page()
    local uci = require "luci.model.uci".cursor()
    local current_text = uci:get("foxhound", "settings", "about_text") or "OpenWRT - Wireless Freedom"
    luci.template.render("foxhound/settings", {
        token = luci.dispatcher.context.authtoken,
        about_text = current_text
    })
end

function action_save_about()
    local http = require "luci.http"
    local uci = require "luci.model.uci".cursor()
    local source = http.source()
    local chunks = {}
    local total = 0

    if source then
        while true do
            local chunk = source()
            if not chunk then break end
            total = total + #chunk
            if total > 8192 then
                http.status(413, "Payload Too Large")
                return
            end
            chunks[#chunks + 1] = chunk
        end
    end
    local json_str = table.concat(chunks)

    if json_str == "" then http.status(400, "Bad Request") return end

    local data = jsonc.parse(json_str)
    if not data then http.status(400, "Invalid Data") return end

    if not check_csrf(data.token) then return end

    local text = tostring(data.text or "")
    text = text:gsub("[%c]", " "):match("^%s*(.-)%s*$")
    
    text = text:gsub("[<>\"'%%;()&]", "")

    if #text > 30 then
        http.status(400, "Text too long")
        return
    end

    if not uci:get("foxhound", "settings") then
        uci:set("foxhound", "settings", "settings")
    end
    uci:set("foxhound", "settings", "about_text", text)
    uci:commit("foxhound")

    http.prepare_content("application/json")
    http.write('{"success":true}')
end

function action_upload_main() save_logo("logo", "logo_url") end
function action_upload_login() save_logo("login-logo", "login_logo_url") end
function action_reset_main() reset_logo("logo", "logo_url") end
function action_reset_login() reset_logo("login-logo", "login_logo_url") end

local function save_bg(filename, uci_key)
    local http = require "luci.http"
    local uci = require "luci.model.uci".cursor()
    local source = http.source()
    local chunks = {}
    local total = 0

    if source then
        while true do
            local chunk = source()
            if not chunk then break end
            total = total + #chunk
            if total > MAX_BG_UPLOAD * 2 then
                http.status(413, "Payload Too Large")
                return
            end
            chunks[#chunks + 1] = chunk
        end
    end
    local json_str = table.concat(chunks)

    if json_str == "" then http.status(400, "Bad Request") return end

    local data = jsonc.parse(json_str)
    if not data or not data.file_data then http.status(400, "Invalid Data") return end

    if not check_csrf(data.token) then return end

    local nixio = require "nixio"
    local decoded = nixio.bin.b64decode(data.file_data)
    if not decoded then http.status(500, "Decode Error") return end

    if #decoded > MAX_BG_UPLOAD then http.status(413, "File Too Large") return end

    if decoded:sub(1, 3) ~= "\255\216\255" then
        http.status(400, "File must be a valid JPEG image")
        return
    end

    local file_path = "/www/luci-static/foxhound/resources/upload/" .. filename
    local fp = io.open(file_path, "wb")
    if not fp then http.status(500, "Write Error") return end
    fp:write(decoded)
    fp:close()

    local web_path = "/luci-static/foxhound/resources/upload/" .. filename
    if not uci:get("foxhound", "settings") then
        uci:set("foxhound", "settings", "settings")
    end
    uci:set("foxhound", "settings", uci_key, web_path)
    uci:commit("foxhound")

    http.prepare_content("application/json")
    http.write('{"success":true}')
end

local function reset_bg(filename, uci_key)
    if not check_csrf() then return end

    local http = require "luci.http"
    local uci = require "luci.model.uci".cursor()
    local fs = require "nixio.fs"
    local p = "/www/luci-static/foxhound/resources/upload/" .. filename
    if fs.access(p) then fs.unlink(p) end
    if not uci:get("foxhound", "settings") then
        uci:set("foxhound", "settings", "settings")
    end
    uci:delete("foxhound", "settings", uci_key)
    uci:commit("foxhound")
    http.prepare_content("application/json")
    http.write('{"success":true}')
end

function action_upload_bg_main()  save_bg("bg-main.jpg",  "bg_main_url")  end
function action_upload_bg_login() save_bg("bg-login.jpg", "bg_login_url") end
function action_reset_bg_main()   reset_bg("bg-main.jpg",  "bg_main_url")  end
function action_reset_bg_login()  reset_bg("bg-login.jpg", "bg_login_url") end

local function get_pkg_manager()
    local out = luci.sys.exec("which apk 2>/dev/null")
    if out and out:match("apk") then return "apk" end
    return "opkg"
end

local function get_current_version(pkg_mgr)
    local out, ver
    if pkg_mgr == "apk" then
        out = luci.sys.exec("apk list --installed 2>/dev/null | grep 'luci-theme-foxhound'")
        if out and out ~= "" then ver = out:match("luci%-theme%-foxhound%-([%d%.]+)") end
    else
        out = luci.sys.exec("opkg list-installed 2>/dev/null | grep 'luci-theme-foxhound'")
        if out and out ~= "" then ver = out:match("luci%-theme%-foxhound%s+%-%s+([%d%.%-]+)") end
    end
    return ver or "unknown"
end

local function strip_v(s) return (s or ""):gsub("^[vV]", ""):gsub("%s+", "") end

local function fetch_github_release()
    local url = "https://api.github.com/repos/fullband7/openwrt-theme-foxhound/releases/latest"

    return luci.sys.exec(
        "uclient-fetch -q -O- --timeout=15 " ..
        "--header='Accept: application/vnd.github+json' " ..
        "--user-agent='OpenWrt-LuCI-Updater/1.0' " ..
        "'" .. url .. "' 2>/dev/null"
    )
end

local function parse_release(json_str)
    if not json_str then return nil end
    local ok, data = pcall(jsonc.parse, json_str)
    if not ok or not data then return nil end
    local assets = {}
    for _, asset in ipairs(data.assets or {}) do
        if asset.browser_download_url then table.insert(assets, asset.browser_download_url) end
    end
    return { tag = data.tag_name, name = data.name, body = data.body or "", assets = assets }
end

local function best_asset(assets, pkg_mgr)
    local ext = (pkg_mgr == "apk") and "%.apk$" or "%.ipk$"
    for _, u in ipairs(assets) do if u:match(ext) then return u end end
    for _, u in ipairs(assets) do if u:match("%.ipk$") or u:match("%.apk$") then return u end end
    return nil
end

local CACHE_FILE = "/tmp/foxhound/update_cache.json"
local CACHE_TTL  = 21600

function action_check()
    local pkg_mgr = get_pkg_manager()
    local current_ver = get_current_version(pkg_mgr)
    local release_cache = nil
    local f = io.open(CACHE_FILE, "r")
    if f then
        local raw = f:read("*a")
        f:close()
        if raw and raw ~= "" then
            local ok, cache = pcall(jsonc.parse, raw)
            if ok and cache and cache.time and (os.time() - cache.time) < CACHE_TTL then release_cache = cache.release end
        end
    end

    if not release_cache then
        local raw = fetch_github_release()
        if not raw then
            luci.http.prepare_content("application/json")
            luci.http.write_json({ error = "Cannot reach GitHub API. Check internet connectivity.", update_available = false, current_version = current_ver, pkg_manager = pkg_mgr })
            return
        end
        local rel = parse_release(raw)
        if not rel or not rel.tag then
            luci.http.prepare_content("application/json")
            luci.http.write_json({ error = "GitHub API responded but release data could not be parsed.", update_available = false, current_version = current_ver, pkg_manager = pkg_mgr })
            return
        end
        release_cache = { tag = rel.tag, name = rel.name, body = rel.body, assets = rel.assets, download_url = best_asset(rel.assets, pkg_mgr) }
        local cache_data = { time = os.time(), release = release_cache }
        luci.sys.exec("mkdir -p /tmp/foxhound 2>/dev/null")
        local tmp_file = CACHE_FILE .. ".tmp"
        local fw = io.open(tmp_file, "w")
        if fw then
            fw:write(jsonc.stringify(cache_data))
            fw:close()
            os.rename(tmp_file, CACHE_FILE)
        end
    end

    local latest_ver = release_cache.tag
    luci.http.prepare_content("application/json")
    luci.http.write_json({ current_version = current_ver, latest_version = latest_ver, release_title = release_cache.name or latest_ver, release_notes = release_cache.body or "", assets = release_cache.assets or {}, download_url = release_cache.download_url, update_available = (strip_v(latest_ver) ~= strip_v(current_ver)), pkg_manager = pkg_mgr })
end