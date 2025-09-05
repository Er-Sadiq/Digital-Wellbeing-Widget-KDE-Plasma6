// logic.js - utility functions used by main.qml

// Format uptime (seconds) into "Xd Yh Zm"
function formatUptime(seconds) {
    if (seconds === undefined || seconds === null || isNaN(seconds)) return "0m"
    seconds = Math.floor(seconds)
    var days = Math.floor(seconds / 86400)
    seconds %= 86400
    var hours = Math.floor(seconds / 3600)
    seconds %= 3600
    var minutes = Math.floor(seconds / 60)

    var parts = []
    if (days > 0) parts.push(days + "d")
    if (hours > 0) parts.push(hours + "h")
    if (minutes > 0) parts.push(minutes + "m")
    if (parts.length === 0) parts.push("0m")
    return parts.join(" ")
}

// Format countdown (seconds) into "MM:SS"
function formatCountdown(s) {
    s = Math.max(0, Math.floor(s || 0))
    var m = Math.floor(s / 60)
    var sec = s % 60
    return m + ":" + (sec < 10 ? "0" + sec : sec)
}

// Extract uptime seconds from systemmonitor data (robust)
function extractUptime(data) {
    if (!data) return null
    var key = "system/uptime"
    if (data[key] !== undefined) {
        var v = (typeof data[key] === "object" && data[key].value !== undefined) ? data[key].value : data[key]
        var n = Number(v)
        if (!isNaN(n)) return n
    }
    var keys = Object.keys(data || {})
    for (var i = 0; i < keys.length; ++i) {
        var k = keys[i]
        if (k && k.toLowerCase().indexOf("uptime") !== -1) {
            var val = data[k]
            var vv = (val && val.value !== undefined) ? val.value : val
            var nn = Number(vv)
            if (!isNaN(nn)) return nn
        }
    }
    return null
}

// Parse /proc/uptime output and return seconds (or null)
function parseProcUptime(stdout) {
    if (!stdout) return null
    var first = stdout.trim().split(/\s+/)[0]
    var secs = parseFloat(first)
    return isNaN(secs) ? null : secs
}
