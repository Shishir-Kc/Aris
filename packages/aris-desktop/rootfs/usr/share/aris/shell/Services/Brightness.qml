pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

// Laptop backlight through brightnessctl. `available` stays false on desktops.
Singleton {
  id: root

  property bool available: false
  property real value: 0
  property bool announce: false

  // Asked for by the brightness keys, so the OSD shows the new level.
  signal osdRequested()

  function refresh(withOsd) {
    if (withOsd) root.announce = true
    reader.running = true
  }

  function set(v) {
    if (!available) return
    root.value = Util.clamp(v, 0.01, 1)
    Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(root.value * 100) + "%"])
  }

  function step(steps) {
    set(Math.round((value + 0.05 * steps) * 20) / 20)
  }

  function icon(v) {
    if (v < 0.34) return "󰃞"
    if (v < 0.67) return "󰃟"
    return "󰃠"
  }

  Process {
    id: reader
    command: ["brightnessctl", "-m", "-c", "backlight", "info"]
    stdout: StdioCollector {
      onStreamFinished: {
        // name,class,current,percent,max
        var f = text.trim().split("\n")[0].split(",")
        var cur = parseInt(f[2], 10)
        var max = parseInt(f[4], 10)
        root.available = f.length >= 5 && max > 0
        if (root.available) root.value = cur / max
        if (root.announce && root.available) root.osdRequested()
        root.announce = false
      }
    }
  }

  Component.onCompleted: refresh(false)
}
