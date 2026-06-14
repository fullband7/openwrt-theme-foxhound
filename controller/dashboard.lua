module("luci.controller.dashboard", package.seeall)

function index()
    entry({"admin"}, call("action_dashboard"), _("Dashboard"), 1)
    entry({"admin", "dashboard"}, call("action_dashboard"), _("Dashboard"), 1)
    entry({"admin", "dashboard", "api"}, call("action_api"))
end

function action_dashboard()
    luci.template.render("dashboard/index", {
        hostname = luci.sys.hostname(),
        uptime = luci.sys.uptime(),
        firmware = luci.sys.exec(". /etc/openwrt_release 2>/dev/null && echo $DISTRIB_DESCRIPTION") or "OpenWrt"
    })
end

function action_api()
    local result = {}

    -- 1. CPU Usage (first widget)
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
        local cores = tonumber(luci.sys.exec("grep -c '^processor' /proc/cpuinfo")) or 1
        local la = luci.sys.exec("cat /proc/loadavg"):match("([%d%.]+ [%d%.]+ [%d%.]+)") or "0.00 0.00 0.00"

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

    -- 2. Memory (second widget)
    local mem_info = {}
    local mem_handle = io.popen("cat /proc/meminfo")
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
    local mem_sreclaimable = mem_info.SReclaimable or 0
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

    -- 3. Storage (third widget)
    local function parse_df(path)
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

    -- 4. Temperature (fourth widget)
    local cpu_val = luci.sys.exec("cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null")
    local cpu_temp = nil
    if cpu_val and cpu_val ~= "" and tonumber(cpu_val) then
        cpu_temp = math.floor(tonumber(cpu_val) / 1000)
    end
    result.temperature = { cpu_temp = cpu_temp }

    -- 5. Wireless (full-width, fifth widget)
    local wireless_result = {}
    local dhcp_leases = {}
    local dhcp_file = io.open("/tmp/dhcp.leases")
    if dhcp_file then
        for line in dhcp_file:lines() do
            local timestamp, mac, ip, name, client_id = line:match("^(%d+)%s+([%w:]+)%s+([%d%.]+)%s+(%S+)%s+(%S+)")
            if mac then
                dhcp_leases[mac:upper()] = {
                    ip = ip,
                    name = name ~= "*" and name or nil
                }
            end
        end
        dhcp_file:close()
    end
    local wifi_ifaces = {"2.4GHz", "5GHz"}
    for _, iface in ipairs(wifi_ifaces) do
        local info = luci.sys.exec("iwinfo \"" .. iface .. "\" info 2>/dev/null")
        local assoclist = luci.sys.exec("iwinfo \"" .. iface .. "\" assoclist 2>/dev/null")
        local ssid = iface
        local carrier = false
        if info and info ~= "" then
            local essid = info:match("ESSID: \"([^\"]+)\"")
            if essid and essid ~= "unknown" then ssid = essid end
            local mode = info:match("Mode:%s*(%S+)")
            if mode and (mode == "Master" or mode == "Client" or mode == "Ad-Hoc") then
                carrier = true
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
            clients = clients
        })
    end
    result.wireless = wireless_result

    -- 6. Ethernet Ports (full-width, sixth widget)
    local network_result = {}
    local cmd = "ls -1 /sys/class/net/"
    local handle = io.popen(cmd)
    local interfaces = handle:read("*a")
    handle:close()
    for iface in interfaces:gmatch("%S+") do
        if iface ~= "lo" and not iface:match("^br-") and not iface:match("^ifb") 
           and not iface:match("^gre") and not iface:match("^tun") 
           and not iface:match("^wg") and not iface:match("^phy") 
           and not iface:match("^sit") and not iface:match("^gretap")
           and not iface:match("^ip6tnl") and not iface:match("^tunl")
           and not iface:match("^mon%.") and not iface:match("^wlan")
           and not iface:match("^wifi") and not iface:match("^hwsim")
           and not iface:match("^imq") and not iface:match("^teql")
           and not iface:match("^docker") and not iface:match("^veth")
           and not iface:match("^erspan") then
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
    table.sort(network_result, function(a, b) return a.name < b.name end)
    result.network = network_result

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end
