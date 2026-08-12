/* FoxHound dashboard widgets
 *
 * SECURITY NOTE: this file builds every widget with document.createElement()/
 * textContent via the mk() helper below - never innerHTML - so values coming
 * from the network (SSIDs, DHCP hostnames, MAC addresses, interface names,
 * sensor labels, etc.) are always inserted as text nodes and can never be
 * parsed as markup.
 */

var cpuPrev = "0,0";

// Safe DOM element builder.
// - attrs.className / attrs.style are handled specially, everything else
//   goes through setAttribute (which never interprets its value as HTML).
// - string/number children are always inserted via createTextNode, so
//   dynamic data can never break out into markup.
function mk(tag, attrs, children) {
    var el = document.createElement(tag);
    if (attrs) {
        for (var key in attrs) {
            if (!Object.prototype.hasOwnProperty.call(attrs, key)) continue;
            var val = attrs[key];
            if (val === undefined || val === null) continue;
            if (key === "className") el.className = val;
            else if (key === "style") el.style.cssText = val;
            else el.setAttribute(key, val);
        }
    }
    if (children !== undefined && children !== null) {
        (Array.isArray(children) ? children : [children]).forEach(function (c) {
            if (c === undefined || c === null) return;
            el.appendChild(
                (typeof c === "string" || typeof c === "number")
                    ? document.createTextNode(String(c))
                    : c
            );
        });
    }
    return el;
}

function clearEl(node) {
    if (!node) return;
    while (node.firstChild) node.removeChild(node.firstChild);
}

function setWidget(id, node) {
    var container = document.getElementById(id);
    if (!container) return;
    clearEl(container);
    if (node !== undefined && node !== null) container.appendChild(node);
}

function loadSystemInfo() {
    var boardFn = L.rpc.declare({ object: "system", method: "board" });
    var infoFn = L.rpc.declare({ object: "system", method: "info" });
    Promise.all([boardFn(), infoFn()]).then(function (res) {
        var board = res[0] || {};
        var info = res[1] || {};
        var modelEl = document.getElementById("model-value");
        if (modelEl && board.model) modelEl.textContent = board.model;
        var uptimeEl = document.getElementById("uptime-value");
        if (uptimeEl && info.uptime) {
            window._uptimeStart = info.uptime;
            window._uptimeLoadedAt = Date.now();
            uptimeEl.textContent = formatUptime(info.uptime);
            startUptimeTicker();
        }
    });
}

function formatUptime(t) {
    return Math.floor(t / 3600) + "h " + Math.floor((t % 3600) / 60) + "m " + Math.floor(t % 60) + "s";
}

function startUptimeTicker() {
    if (!window._uptimeStart || window._uptimeLoadedAt === undefined) return;
    var el = document.getElementById("uptime-value");
    if (!el) return;
    tick();
    setInterval(tick, 1000);
    function tick() {
        var elapsed = (Date.now() - window._uptimeLoadedAt) / 1000;
        el.textContent = formatUptime(window._uptimeStart + elapsed);
    }
}

function renderCPUWidget(t) {
    var usage = Number(t.usage) || 0;
    var loadavg = t.loadavg || "0.00 0.00 0.00";
    var cores = (t.cores !== undefined && t.cores !== null) ? t.cores : "?";
    var gradient = usage < 50
        ? "linear-gradient(90deg, #4CAF50, #8BC34A)"
        : usage < 80
            ? "linear-gradient(90deg, #FF9800, #FFC107)"
            : "linear-gradient(90deg, #F44336, #FF5722)";

    var bar = mk("div", { className: "cbi-progressbar cpu-bar", title: usage + "%" },
        mk("div", { style: "width:" + usage + "%; background: " + gradient + ";" }, usage + "%")
    );

    var table = mk("table", { className: "table" }, [
        mk("tr", { className: "tr" }, [
            mk("td", { className: "td left", width: "33%" }, "CPU Usage"),
            mk("td", { className: "td left" }, bar)
        ]),
        mk("tr", { className: "tr" }, [
            mk("td", { className: "td left", width: "33%" }, "Cores"),
            mk("td", { className: "td left" }, String(cores))
        ]),
        mk("tr", { className: "tr" }, [
            mk("td", { className: "td left", width: "33%" }, "Load Average"),
            mk("td", { className: "td left" }, String(loadavg))
        ])
    ]);

    setWidget("cpu-widget", table);
}

function renderMemoryWidget(t) {
    var total = Number(t.total) || 0;
    var free = Number(t.free) || 0;
    var buffered = Number(t.buffered) || 0;
    var cached = Number(t.cached) || 0;
    var available = Number(t.available) || (free + buffered);
    var used = total - available;
    var pct = total > 0 ? Math.floor((used / total) * 100) : 0;

    var rows = [
        mk("tr", { className: "tr" }, [
            mk("td", { className: "td left", width: "33%" }, "Total Available"),
            mk("td", { className: "td left" }, formatBytes(available) + " / " + formatBytes(total))
        ]),
        mk("tr", { className: "tr" }, [
            mk("td", { className: "td left", width: "33%" }, "Used"),
            mk("td", { className: "td left" }, [
                mk("div", { className: "cbi-progressbar", title: pct + "%" },
                    mk("div", { style: "width:" + pct + "%; background: linear-gradient(90deg, #4CAF50, #8BC34A);" }, pct + "%")
                ),
                formatBytes(used) + " / " + formatBytes(total)
            ])
        ])
    ];

    if (buffered > 0) {
        rows.push(mk("tr", { className: "tr" }, [
            mk("td", { className: "td left", width: "33%" }, "Buffered"),
            mk("td", { className: "td left" }, formatBytes(buffered))
        ]));
    }
    if (cached > 0) {
        rows.push(mk("tr", { className: "tr" }, [
            mk("td", { className: "td left", width: "33%" }, "Cached"),
            mk("td", { className: "td left" }, formatBytes(cached))
        ]));
    }

    setWidget("memory-widget", mk("table", { className: "table" }, rows));
}

function renderStorageWidget(t) {
    var table = mk("table", { className: "table" });

    if (t.root) {
        var rUsed = Number(t.root.used) || 0;
        var rTotal = Number(t.root.total) || 0;
        var rPct = rTotal > 0 ? Math.floor((rUsed / rTotal) * 100) : 0;
        table.appendChild(mk("tr", { className: "tr" }, [
            mk("td", { className: "td left", width: "33%" }, "Disk space"),
            mk("td", { className: "td left" }, [
                mk("div", { className: "cbi-progressbar", title: rPct + "%" },
                    mk("div", { style: "width:" + rPct + "%; background: linear-gradient(90deg, #FF9800, #FFC107);" }, rPct + "%")
                ),
                mk("small", null, formatBytes(rUsed) + " / " + formatBytes(rTotal))
            ])
        ]));
    }

    if (t.tmp) {
        var tUsed = Number(t.tmp.used) || 0;
        var tTotal = Number(t.tmp.total) || 0;
        var tPct = tTotal > 0 ? Math.floor((tUsed / tTotal) * 100) : 0;
        table.appendChild(mk("tr", { className: "tr" }, [
            mk("td", { className: "td left", width: "33%" }, "Temp space"),
            mk("td", { className: "td left" }, [
                mk("div", { className: "cbi-progressbar", title: tPct + "%" },
                    mk("div", { style: "width:" + tPct + "%; background: linear-gradient(90deg, #2196F3, #64B5F6);" }, tPct + "%")
                ),
                mk("small", null, formatBytes(tUsed) + " / " + formatBytes(tTotal))
            ])
        ]));
    }

    setWidget("storage-widget", table);
}

function mergeTrafficData(list, stats) {
    return list.map(function (item) {
        var s = stats[item.name];
        item.rx_bytes = (s && s.rx_bytes) || 0;
        item.tx_bytes = (s && s.tx_bytes) || 0;
        return item;
    });
}

function renderNetworkWidget(list) {
    if (!Array.isArray(list)) list = [];
    var ports = list.filter(function (item) {
        return typeof item.name === "string" &&
            !item.name.match(/^[25]\.?4?GHz$/i) &&
            !item.name.match(/^wlan/) &&
            !item.name.match(/^phy/);
    });

    if (ports.length === 0) {
        setWidget("network-widget", mk("div", { style: "color:#999;" }, "No Ethernet ports found"));
        return;
    }

    var wrap = mk("div", { style: "display: flex; flex-wrap: wrap; gap: 12px;" });
    ports.forEach(function (item) {
        var up = !!item.carrier;
        var speed = item.speed && item.speed > 0 ? Number(item.speed) : null;
        var bg = up ? "rgba(76, 175, 80, 0.12)" : "rgba(255, 255, 255, 0.03)";
        var border = up ? "rgba(76, 175, 80, 0.5)" : "rgba(255, 255, 255, 0.08)";
        var color = up ? "#4CAF50" : "#888";
        var dot = up ? "●" : "○";
        var label = /wan/i.test(item.name) ? "WAN" : "LAN";
        var speedLabel = "";
        if (up && speed) {
            speedLabel = speed >= 1000 ? (speed / 1000).toFixed(1) + " Gbps" : speed + " Mbps";
        }

        var card = mk("div", { style: "background: " + bg + "; border: 1px solid " + border + "; border-radius: 12px; padding: 16px; text-align: center; min-width: 100px; flex: 1;" }, [
            mk("div", { style: "font-size: 10px; text-transform: uppercase; color: #999; letter-spacing: 0.5px; margin-bottom: 6px;" }, label),
            mk("div", { style: "font-size: 16px; color: #fff; font-weight: 700; margin-bottom: 6px;" }, item.name),
            mk("div", { style: "font-size: 12px; color: " + color + "; font-weight: 500;" }, dot + " " + (up ? "Online" : "No Link"))
        ]);
        if (speedLabel) {
            card.appendChild(mk("div", { style: "font-size: 11px; color: #aaa; margin-top: 4px;" }, speedLabel));
        }
        wrap.appendChild(card);
    });

    setWidget("network-widget", wrap);
}

function freqIs24(t) {
    if (t.freq) return parseFloat(t.freq) < 3;
    return t.iface.indexOf("2.4") !== -1 || t.iface.indexOf("2g") !== -1 || t.iface.indexOf("radio0") !== -1;
}

function freqLabel(t) {
    if (t.freq) {
        var f = parseFloat(t.freq);
        if (f < 3) return "2.4GHz";
        if (f < 6) return "5GHz";
        return "6GHz";
    }
    return t.iface;
}

function renderWirelessWidget(list) {
    if (!Array.isArray(list)) list = [];

    if (list.length === 0) {
        setWidget("wireless-widget", mk("div", { style: "padding:20px;text-align:center;color:#999;" }, "No wireless radios found"));
        return;
    }

    var frag = document.createDocumentFragment();

    var summary = mk("div", { style: "display: flex; flex-wrap: wrap; gap: 12px; margin-bottom: 20px;" });
    list.forEach(function (radio) {
        var up = !!radio.carrier;
        var color = up ? "#42A5F5" : "#888";
        var statusLabel = up ? "Active" : "Down";
        var dot = up ? "●" : "○";
        var bg = up ? "rgba(33, 150, 243, 0.12)" : "rgba(255, 255, 255, 0.03)";
        var border = up ? "rgba(33, 150, 243, 0.5)" : "rgba(255, 255, 255, 0.08)";
        summary.appendChild(mk("div", { style: "background: " + bg + "; border: 1px solid " + border + "; border-radius: 10px; line-height:1.5; padding: 14px 18px; text-align: center; min-width: 120px; flex: 1;" }, [
            mk("div", { style: "font-size: 16px; text-transform: uppercase; color: #999; letter-spacing: 0.5px; margin-bottom: 6px;" }, "WiFi"),
            mk("div", { style: "font-size: 25px; color: #fff; font-weight: 700; margin-bottom: 6px;" }, freqLabel(radio)),
            mk("div", { style: "font-size: 17px; color: " + color + "; font-weight: 500;" }, dot + " " + statusLabel)
        ]));
    });
    frag.appendChild(summary);

    var anyClients = false;
    list.forEach(function (radio) {
        var clients = Array.isArray(radio.clients)
            ? radio.clients
            : (radio.clients && typeof radio.clients === "object" ? Object.values(radio.clients) : []);
        if (!clients || clients.length === 0) return;
        anyClients = true;

        var is24 = freqIs24(radio);
        var bandLabel = freqLabel(radio);
        var bandBg = is24 ? "#edf0f1" : "#C62828";
        var bandText = is24 ? "#000" : "#fff";

        var table = mk("table", { className: "table" }, [
            mk("tr", { className: "tr", style: "border-bottom: 1px solid rgba(255,255,255,0.1);" }, [
                mk("th", { style: "color:#999; font-size:14px; padding:6px;" }, "Hostname"),
                mk("th", { style: "color:#999; font-size:14px; padding:6px;" }, "IP Address"),
                mk("th", { style: "color:#999; font-size:14px; padding:6px;" }, "MAC"),
                mk("th", { style: "color:#999; font-size:14px; padding:6px;" }, "Signal")
            ])
        ]);

        clients.forEach(function (client) {
            var hasSignal = client.signal !== undefined && client.signal !== null && !isNaN(Number(client.signal));
            var signalNum = hasSignal ? Number(client.signal) : null;
            var signalColor = signalNum !== null && signalNum > -50
                ? "#4CAF50"
                : signalNum !== null && signalNum > -70
                    ? "#FF9800"
                    : "#F44336";

            table.appendChild(mk("tr", { className: "tr", style: "border-bottom: 1px solid rgba(255,255,255,0.03);" }, [
                mk("td", { style: "color:#fff; font-size:14px; padding:6px;" }, client.hostname || "-"),
                mk("td", { style: "color:#90CAF9; font-size:14px; padding:6px;" }, client.ip || "-"),
                mk("td", { style: "color:#ccc; font-size:14px; padding:6px; font-family:monospace;" }, client.mac || "-"),
                mk("td", { style: "color:" + signalColor + "; font-size:14px; padding:6px; font-weight:600;" }, (signalNum !== null ? signalNum : "?") + " dBm")
            ]));
        });

        frag.appendChild(mk("div", { style: "background:#24313e; border-radius: 12px; padding: 16px; margin-bottom: 16px;" }, [
            mk("div", { style: "display: flex; align-items: center; gap: 12px; margin-bottom: 12px;" }, [
                mk("span", { style: "background: #1f7fd1; color: #fff; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 700;" }, radio.ssid || radio.iface),
                mk("span", { style: "background: " + bandBg + "; color: " + bandText + "; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 700; margin-right: 4px;" }, bandLabel),
                mk("span", { style: "color: #aaa; font-size: 11px;" }, "\uD83D\uDC65 " + clients.length + " clients")
            ]),
            mk("div", { style: "overflow-x: auto;text-align:left;" }, table)
        ]));
    });

    if (!anyClients) {
        frag.appendChild(mk("div", { style: "padding:20px;text-align:center;color:#999;" }, "No connected clients"));
    }

    setWidget("wireless-widget", frag);
}

// Temperature widget.
// The backend (dashboard.lua) scans every sensor it can find (SoC thermal
// zone, WiFi radio hwmon, disk hwmon, ...) and returns them all as
// result.temperatures = [{label, value}, ...], since on some hardware
// (e.g. this router) there's no dedicated CPU/SoC thermal zone at all and
// the only real reading available comes from a different chip (WiFi radio,
// disk controller, etc).
//
// By request, this widget intentionally shows just ONE reading - whichever
// sensor the backend put first in the list - styled exactly like the
// original single-value display, and always labelled "CPU Temp" regardless
// of which physical sensor it actually came from.
function renderTempWidget(list) {
    if (!Array.isArray(list) || list.length === 0) {
        setWidget("temp-widget", mk("div", { style: "padding:20px;text-align:center;color:#999;" }, "Sensor unavailable"));
        return;
    }

    var temp = Number(list[0] && list[0].value);
    if (isNaN(temp)) {
        setWidget("temp-widget", mk("div", { style: "padding:20px;text-align:center;color:#999;" }, "Sensor unavailable"));
        return;
    }

    var color = temp < 70 ? "#4CAF50" : temp < 90 ? "#FF9800" : "#F44336";
    var status = temp < 70 ? "Normal" : temp < 90 ? "Hot" : "Critical";
    setWidget("temp-widget", mk("div", { style: "line-height:1.2; text-align:center;" }, [
        mk("div", { style: "font-size:30px; margin-bottom:6px;" }, "\uD83C\uDF21\uFE0F"),
        mk("div", { style: "font-size:16px; color:#aaa; text-transform:uppercase; letter-spacing:0.5px;" }, "CPU Temp"),
        mk("div", { style: "font-size:34px; font-weight:700; color:" + color + "; margin-top:6px;" }, temp + "°C"),
        mk("div", { style: "font-size:14px; color:" + color + "; margin-top:4px;" }, status)
    ]));
}

function renderInternetWidget(t) {
    var el = document.getElementById("internet-value");
    if (!el) return;
    var status = t.status || "Checking...";
    el.textContent = status;
    el.style.color = status === "Online" ? "#00b386" : "#F44336";
}

function loadDashboardData() {
    fetch("/cgi-bin/luci/admin/dashboard/api?cpu_prev=" + encodeURIComponent(cpuPrev) + "&token=" + encodeURIComponent(window.FOXHOUND_API_TOKEN || ""))
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (data.cpu && data.cpu.prev) cpuPrev = data.cpu.prev;
            if (data.network && Array.isArray(data.network) && data.port_stats) {
                data.network = mergeTrafficData(data.network, data.port_stats);
            }
            try { renderCPUWidget(data.cpu || { usage: 0, cores: "?", loadavg: "0.00 0.00 0.00" }); } catch (e) {}
            try { renderMemoryWidget(data.memory || {}); } catch (e) {}
            try { renderStorageWidget(data.storage || {}); } catch (e) {}
            try { renderTempWidget(Array.isArray(data.temperatures) ? data.temperatures : []); } catch (e) {}
            try { renderNetworkWidget(Array.isArray(data.network) ? data.network : []); } catch (e) {}
            try { renderWirelessWidget(Array.isArray(data.wireless) ? data.wireless : []); } catch (e) {}
            try { renderInternetWidget(data.internet || { status: "Checking..." }); } catch (e) {}
        })
        .catch(function (err) { console.error("Error loading dashboard data:", err); });
}

function formatBytes(n) {
    if (isNaN(n) || n <= 0) return "0 B";
    var units = ["B", "KB", "MB", "GB", "TB"];
    var i = Math.floor(Math.log(n) / Math.log(1024));
    return parseFloat((n / Math.pow(1024, i)).toFixed(1)) + " " + units[i];
}

cpuPrev = "0,0";
window.addEventListener("load", function () {
    setTimeout(function () {
        loadSystemInfo();
        loadDashboardData();
        setInterval(loadDashboardData, 2000);
    }, 1000);
});
