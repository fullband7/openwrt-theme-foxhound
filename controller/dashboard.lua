module("luci.controller.foxhound.dashboard", package.seeall)

local nixio = require "nixio"

function index()
    entry({"admin"}, call("action_dashboard"), _("Dashboard"), 1)
    entry({"admin", "dashboard"}, call("action_dashboard"), _("Dashboard"), 1)
    entry({"admin", "dashboard", "api"}, call("action_api"))
end

function action_dashboard()
    luci.template.render("foxhound/dashboard", {
        hostname = luci.sys.hostname(),
        uptime = luci.sys.uptime(),
        firmware = luci.sys.exec(". /etc/openwrt_release 2>/dev/null && echo $DISTRIB_DESCRIPTION") or "OpenWrt"
    })
end

local function is_safe_iface(name)
    if type(name) ~= "string" or #name == 0 or #name > 15 then
        return false
    end
    return not name:match("[^%w%.%-%_]")
end

local function sanitize(str)
    if type(str) ~= "string" then
        return nil
    end
    str = str:gsub("[%c]", "")
    if #str > 64 then
        str = str:sub(1, 64)
    end
    return str
end

local function get_wifi_interfaces()
    local ifaces = {}
    local seen = {}

    local iwinfo_raw = luci.sys.exec("iwinfo 2>/dev/null")
    if iwinfo_raw and iwinfo_raw ~= "" then
        for iface in iwinfo_raw:gmatch("([^\n%s]+)%s+ESSID:") do
            if not seen[iface] and is_safe_iface(iface) then
                seen[iface] = true
                table.insert(ifaces, iface)
            end
        end
    end

    if #ifaces == 0 then
        local dir = nixio.fs.dir("/sys/class/net/")
        if dir then
            for iface in dir do
                if not seen[iface] and is_safe_iface(iface) and (
                    iface:match("^wlan%d") or
                    iface:match("^rai?%d") or
                    iface:match("^ra%d") or
                    iface:match("^ath%d") or
                    iface:match("^mt%d")
                ) then
                    seen[iface] = true
                    table.insert(ifaces, iface)
                end
            end
        end
    end

    return ifaces
end

function action_api()
    local result = {}

    local prev_str = luci.http.formvalue("cpu_prev") or "0,0"
    local prev_total, prev_idle = prev_str:match("([^,]+),([^,]+)")
    prev_total = tonumber(prev_total) or 0
    prev_idle = tonumber(prev_idle) or 0

    local stat = io.open("/proc/stat", "r")
    if stat then
        local line = stat:read("*l")
        stat:close()
        local fields = {}
        for token in line:gmatch("%S+") do
            fields[#fields + 1] = token
        end
        local user = tonumber(fields[2]) or 0
        local nice = tonumber(fields[3]) or 0
        local system = tonumber(fields[4]) or 0
        local idle = tonumber(fields[5]) or 0
        local iowait = tonumber(fields[6]) or 0
        local irq = tonumber(fields[7]) or 0
        local total = user + nice + system + idle + iowait + irq

        local usage = 0
        if total > prev_total then
            local diff_total = total - prev_total
            local diff_idle = idle - prev_idle
            if diff_total > 0 then
                usage = math.floor(((diff_total - diff_idle) / diff_total) * 100 + 0.5)
            end
        end
        
        local cores = 0
        local cpuinfo = io.open("/proc/cpuinfo", "r")
        if cpuinfo then
            for info_line in cpuinfo:lines() do
                if info_line:match("^processor") then
                    cores = cores + 1
                end
            end
            cpuinfo:close()
        end
        if cores == 0 then cores = 1 end

        local la = "0.00 0.00 0.00"
        local loadavg_file = io.open("/proc/loadavg", "r")
        if loadavg_file then
            local la_line = loadavg_file:read("*l")
            if la_line then
                la = la_line:match("([%d%.]+ [%d%.]+ [%d%.]+)") or "0.00 0.00 0.00"
            end
            loadavg_file:close()
        end

        result.cpu = {
            usage = usage,
            cores = tostring(cores),
            loadavg = la,
            prev = total .. "," .. idle
        }
    else
        result.cpu = {
            usage = 0,
            cores = "1",
            loadavg = "0.00 0.00 0.00",
            prev = "0,0"
        }
    end

    local mem_info = {}
    local mem_handle = io.open("/proc/meminfo", "r")
    if mem_handle then
        for line in mem_handle:lines() do
            local key, value = line:match("^(%w+):%s+(%d+)")
            if key and value then
                mem_info[key] = tonumber(value)
            end
        end
        mem_handle:close()
    end
    local mem_total = mem_info.MemTotal or 0
    local mem_free = mem_info.MemFree or 0
    local mem_buffers = mem_info.Buffers or 0
    local mem_cached = mem_info.Cached or 0
    local mem_available = mem_info.MemAvailable or (mem_free + mem_buffers + mem_cached)
    local swap_total = mem_info.SwapTotal or 0
    local swap_free = mem_info.SwapFree or 0
    result.memory = {
        total = mem_total * 1024,
        free = mem_free * 1024,
        buffered = mem_buffers * 1024,
        cached = mem_cached * 1024,
        available = mem_available * 1024,
        swap_total = swap_total * 1024,
        swap_free = swap_free * 1024
    }

    local function parse_df(path)
        local SAFE_DF_PATHS = { ["/"] = true, ["/tmp"] = true }
        if not SAFE_DF_PATHS[path] then return nil end
        local cmd = "df -k " .. path .. " 2>/dev/null | tail -1"
        local out = luci.sys.exec(cmd)
        if out and out ~= "" then
            local filesystem, total, used, free = out:match("^(%S+)%s+(%d+)%s+(%d+)%s+(%d+)")
            if total then
                return {
                    total = tonumber(total) * 1024,
                    used = tonumber(used) * 1024,
                    free = tonumber(free) * 1024
                }
            end
        end
        return nil
    end
    local root_space = parse_df("/")
    local tmp_space = parse_df("/tmp")
    result.storage = {
        root = root_space,
        tmp = tmp_space
    }

    local cpu_temp = nil
    local temp_file = io.open("/sys/class/thermal/thermal_zone0/temp", "r")
    if temp_file then
        local cpu_val = temp_file:read("*l")
        temp_file:close()
        if cpu_val and cpu_val ~= "" and tonumber(cpu_val) then
            cpu_temp = math.floor(tonumber(cpu_val) / 1000)
        end
    end
    result.temperature = { cpu_temp = cpu_temp }

    local wireless_result = {}
    local dhcp_leases = {}
    local dhcp_file = io.open("/tmp/dhcp.leases")
    if dhcp_file then
        for line in dhcp_file:lines() do
            local timestamp, mac, ip, name, client_id = line:match("^(%d+)%s+([%w:]+)%s+([%d%.]+)%s+(%S+)%s+(%S+)")
            if mac then
                local hostname = name ~= "*" and sanitize(name) or nil
                dhcp_leases[mac:upper()] = {
                    ip = ip,
                    name = hostname
                }
            end
        end
        dhcp_file:close()
    end

    local wifi_ifaces = get_wifi_interfaces()

    for _, iface in ipairs(wifi_ifaces) do
        if is_safe_iface(iface) then
            local info = luci.sys.exec("iwinfo -- " .. iface .. " info 2>/dev/null")
            local assoclist = luci.sys.exec("iwinfo -- " .. iface .. " assoclist 2>/dev/null")
            local ssid = iface
            local carrier = false
            local freq = nil

            if info and info ~= "" then
                local essid = info:match("ESSID: \"([^\"]+)\"")
                if essid and essid ~= "unknown" then
                    ssid = sanitize(essid) or iface
                end
                local mode = info:match("Mode:%s*(%S+)")
                if mode and (mode == "Master" or mode == "Client" or mode == "Ad-Hoc") then
                    carrier = true
                end
                local freq_val = info:match("Channel:%s*%d+%s*%(([%d%.]+)%s*GHz%)")
                if freq_val then
                    freq = freq_val
                end
            end

            local clients = {}
            if assoclist and assoclist ~= "" then
                for line in assoclist:gmatch("[^\r\n]+") do
                    local mac = line:match("^([A-Fa-f0-9:]+)")
                    if mac then
                        local signal = line:match("([%d%-]+)%s*dBm")
                        mac = mac:upper()
                        local lease = dhcp_leases[mac]
                        table.insert(clients, {
                            mac = mac,
                            signal = signal and tonumber(signal) or nil,
                            ip = lease and lease.ip or nil,
                            hostname = lease and lease.name or nil
                        })
                    end
                end
            end

            table.insert(wireless_result, {
                iface = iface,
                ssid = ssid,
                carrier = carrier,
                freq = freq,
                clients = clients
            })
        end
    end
    result.wireless = wireless_result

    local network_result = {}
    local wifi_iface_set = {}
    for _, iface in ipairs(wifi_ifaces) do
        wifi_iface_set[iface] = true
    end

    local ignore_patterns = {
        "^br-", "^ifb", "^gre", "^tun", "^wg", "^phy", "^sit", "^gretap",
        "^ip6tnl", "^tunl", "^mon%.", "^wlan", "^wifi", "^hwsim",
        "^imq", "^teql", "^docker", "^veth", "^erspan"
    }

    local net_dir = nixio.fs.dir("/sys/class/net/")
    if net_dir then
        for iface in net_dir do
            if is_safe_iface(iface) then
                local ignore = (iface == "lo") or (wifi_iface_set[iface] == true)
                if not ignore then
                    for _, pattern in ipairs(ignore_patterns) do
                        if iface:match(pattern) then
                            ignore = true
                            break
                        end
                    end
                end

                if not ignore then
                    local carrier = false
                    local carrier_file = io.open("/sys/class/net/" .. iface .. "/carrier", "r")
                    if carrier_file then
                        carrier = carrier_file:read("*n") == 1
                        carrier_file:close()
                    end
                    local speed = nil
                    local speed_file = io.open("/sys/class/net/" .. iface .. "/speed", "r")
                    if speed_file then
                        speed = speed_file:read("*n")
                        speed_file:close()
                    end
                    local duplex = nil
                    local duplex_file = io.open("/sys/class/net/" .. iface .. "/duplex", "r")
                    if duplex_file then
                        duplex = duplex_file:read("*l")
                        duplex_file:close()
                    end
                    table.insert(network_result, {
                        name = iface,
                        carrier = carrier,
                        speed = speed,
                        duplex = duplex
                    })
                end
            end
        end
    end
    table.sort(network_result, function(a, b) return a.name < b.name end)
    result.network = network_result

    local cache_dir = "/tmp/foxhound"
    luci.sys.exec("mkdir -p " .. cache_dir)

    local status_file_path = cache_dir .. "/internet_status"
    local current_time = os.time()
    local file_stat = nixio.fs.stat(status_file_path)
    local last_check = file_stat and file_stat.mtime or 0

    if not file_stat or (current_time - last_check > 30) then
        luci.sys.exec("sh -c '(ping -c 1 -W 1 -q 1.1.1.1 >/dev/null && echo Online || echo Offline) > " .. cache_dir .. "/internet_status.tmp && mv " .. cache_dir .. "/internet_status.tmp " .. status_file_path .. "' >/dev/null 2>&1 &")
    end

    local internet_status = "Checking"
    local status_file = io.open(status_file_path, "r")
    if status_file then
        local line = status_file:read("*l")
        status_file:close()
        if line then
            internet_status = line:match("^%s*(%w+)%s*$") or "Offline"
        end
    end
    
    result.internet = {
        status = internet_status
    }

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end