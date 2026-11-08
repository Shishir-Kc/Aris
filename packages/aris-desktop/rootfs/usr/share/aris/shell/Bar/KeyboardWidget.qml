import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

// Active keyboard layout; hidden with a single layout. Click cycles.
BarButton {
  id: root
  property var options: ({})
  property var bar: null
  property var layouts: []
  property int index: 0
  readonly property bool shown: layouts.length > 1

  height: bar ? bar.size : 26
  text: layouts.length > 0 ? String(layouts[Math.min(index, layouts.length - 1)]).toUpperCase() : ""
  onClicked: function() {
    Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
  }

  Process {
    id: reader
    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var kbs = JSON.parse(text).keyboards || []
          var main = kbs.filter(function(k) { return k.main })[0] || kbs[0]
          if (!main) return
          root.layouts = String(main.layout || "").split(",").filter(function(s) { return s !== "" })
          root.index = main.active_layout_index || 0
        } catch (e) {}
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var n = String(event.name)
      if (n === "activelayout" || n === "configreloaded") reader.running = true
    }
  }

  Component.onCompleted: reader.running = true
}
