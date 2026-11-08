pragma Singleton
import QtQuick
import Quickshell

QtObject {
  function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v))
  }

  // Single-quote a string for sh -c.
  function shq(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'"
  }

  function sh(cmd) {
    Quickshell.execDetached(["sh", "-c", cmd])
  }

  // Lua string literal for Hyprland dispatch expressions.
  function lua(s) {
    return '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"'
  }

  // ISO 8601 week number, for the 'ww' clock token Qt doesn't know.
  function isoWeek(date) {
    var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    var day = d.getUTCDay() || 7
    d.setUTCDate(d.getUTCDate() + 4 - day)
    var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
    return Math.ceil(((d - yearStart) / 86400000 + 1) / 7)
  }

  // Qt.formatDateTime plus 'ww' (ISO week, zero-padded).
  function formatDate(date, format) {
    var f = String(format || "")
    if (f.indexOf("ww") !== -1) {
      var w = isoWeek(date)
      f = f.replace(/ww/g, "'" + (w < 10 ? "0" : "") + w + "'").replace(/''/g, "")
    }
    return Qt.formatDateTime(date, f)
  }

  function durationText(seconds) {
    var s = Math.round(Number(seconds) || 0)
    if (s <= 0) return ""
    var h = Math.floor(s / 3600)
    var m = Math.floor((s % 3600) / 60)
    return h > 0 ? h + "h " + m + "m" : m + "m"
  }
}
