module("luci.controller.dashboard.update", package.seeall)
local jsonc = require "luci.jsonc"

function index()
    entry({"admin", "system", "fh-update"}, call("action_page"), _("Theme Update"), 90)
    entry({"admin", "system", "fh-update", "check"}, call("action_check"))
    entry({"admin", "system", "fh-update", "install"}, call("action_install"))
end

local function get_pkg_manager()
    local out = luci.sys.exec("which apk 2>/dev/null")
    if out and out:match("apk") then return "apk" end
    return "opkg"
end

local function get_current_version(pkg_mgr)
    local out, ver
    if pkg_mgr == "apk" then
        out = luci.sys.exec("apk list --installed 2>/dev/null | grep 'luci-theme-foxhound'")
        if out and out ~= "" then
            ver = out:match("luci%-theme%-foxhound%-([%d%.]+)")
        end
    else
        out = luci.sys.exec("opkg list-installed 2>/dev/null | grep 'luci-theme-foxhound'")
        if out and out ~= "" then
            ver = out:match("luci%-theme%-foxhound%s+%-%s+([%d%.%-]+)")
        end
    end
    return ver or "unknown"
end

local function strip_v(s)
    return (s or ""):gsub("^[vV]", ""):gsub("%s+", "")
end

local function fetch_github_release()
    local url = "https://api.github.com/repos/fullband7/openwrt-theme-foxhound/releases/latest"
    local out = luci.sys.exec(
        "curl -sf --max-time 15 --max-redirs 2 " ..
        "-H 'Accept: application/vnd.github+json' " ..
        "-H 'User-Agent: OpenWrt-LuCI-Updater/1.0' " ..
        "'" .. url .. "' 2>/dev/null"
    )
    return out and out ~= "" and out or nil
end

local function parse_release(json_str)
    if not json_str then return nil end
    local ok, data = pcall(jsonc.parse, json_str)
    if not ok or not data then return nil end
    
    local assets = {}
    for _, asset in ipairs(data.assets or {}) do
        if asset.browser_download_url then
            table.insert(assets, asset.browser_download_url)
        end
    end

    return {
        tag = data.tag_name,
        name = data.name,
        body = data.body or "",
        assets = assets
    }
end

local function best_asset(assets, pkg_mgr)
    local ext = (pkg_mgr == "apk") and "%.apk$" or "%.ipk$"
    for _, u in ipairs(assets) do if u:match(ext) then return u end end
    for _, u in ipairs(assets) do if u:match("%.ipk$") or u:match("%.apk$") then return u end end
    return nil
end

function action_page()
    luci.template.render("dashboard/update", {})
end

local CACHE_FILE = "/tmp/fh-update-cache.json"
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
            local cache = jsonc.parse(raw)
            if cache and cache.time and (os.time() - cache.time) < CACHE_TTL then
                release_cache = cache.release
            end
        end
    end

    if not release_cache then
        local raw = fetch_github_release()
        if not raw then
            luci.http.prepare_content("application/json")
            luci.http.write_json({
                error = "Cannot reach GitHub API. Check internet connectivity.",
                update_available = false,
                current_version = current_ver,
                pkg_manager = pkg_mgr
            })
            return
        end

        local rel = parse_release(raw)
        if not rel or not rel.tag then
            luci.http.prepare_content("application/json")
            luci.http.write_json({
                error = "GitHub API responded but release data could not be parsed.",
                update_available = false,
                current_version = current_ver,
                pkg_manager = pkg_mgr
            })
            return
        end

        release_cache = {
            tag = rel.tag,
            name = rel.name,
            body = rel.body,
            assets = rel.assets,
            download_url = best_asset(rel.assets, pkg_mgr)
        }

        local cache_data = {
            time = os.time(),
            release = release_cache
        }
        local fw = io.open(CACHE_FILE, "w")
        if fw then
            fw:write(jsonc.stringify(cache_data))
            fw:close()
        end
    end

    local latest_ver = release_cache.tag
    local update_available = (strip_v(latest_ver) ~= strip_v(current_ver))

    local result = {
        current_version = current_ver,
        latest_version  = latest_ver,
        release_title   = release_cache.name or latest_ver,
        release_notes   = release_cache.body or "",
        assets          = release_cache.assets or {},
        download_url    = release_cache.download_url,
        update_available = update_available,
        pkg_manager     = pkg_mgr
    }

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function action_install()
    local pkg_mgr = luci.http.formvalue("pkg_manager") or "opkg"
    local url     = luci.http.formvalue("url") or ""

    if not url:match("^https://github%.com/fullband7/openwrt%-theme%-foxhound/releases/download/") then
        luci.http.prepare_content("application/json")
        luci.http.write_json({ success = false, error = "Invalid download URL." })
        return
    end
    if pkg_mgr ~= "opkg" and pkg_mgr ~= "apk" then
        luci.http.prepare_content("application/json")
        luci.http.write_json({ success = false, error = "Unknown package manager." })
        return
    end

    local ext      = (pkg_mgr == "apk") and "apk" or "ipk"
    local tmp_file = "/tmp/fh-update." .. ext

    luci.sys.exec("rm -f " .. tmp_file)
    luci.sys.exec("curl -sfL --max-time 90 --max-redirs 2 -H 'User-Agent: OpenWrt-LuCI-Updater/1.0' -o " .. tmp_file .. " '" .. url .. "' 2>/dev/null")

    local fcheck = io.open(tmp_file, "rb")
    if not fcheck then
        luci.http.prepare_content("application/json")
        luci.http.write_json({ success = false, error = "Download failed." })
        return
    end
    local fsize = fcheck:seek("end"); fcheck:close()
    if fsize < 1024 then
        luci.sys.exec("rm -f " .. tmp_file)
        luci.http.prepare_content("application/json")
        luci.http.write_json({ success = false, error = "Downloaded file too small (" .. fsize .. " bytes)." })
        return
    end

    local out
    if pkg_mgr == "apk" then
        out = luci.sys.exec("apk add --allow-untrusted " .. tmp_file .. " 2>&1") or ""
    else
        out = luci.sys.exec("opkg install --force-reinstall " .. tmp_file .. " 2>&1") or ""
    end
    luci.sys.exec("rm -f " .. tmp_file)

    local ok = not out:lower():match("error") and not out:lower():match("failed")
    
    luci.http.prepare_content("application/json")
    os.remove(CACHE_FILE)
    luci.http.write_json({ 
        success = ok, 
        output = out:sub(1, 4096) 
    })
end