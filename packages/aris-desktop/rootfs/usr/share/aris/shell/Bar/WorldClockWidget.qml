import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets

// A globe; click for the time in each configured city.
BarButton {
  id: root
  property var options: ({})
  property var bar: null
  property var rows: []
  readonly property var cities: options.cities || []
  readonly property bool shown: cities.length > 0

  height: bar ? bar.size : 26
  icon: "󰇧"
  active: panel.visible
  onClicked: { panel.toggle(); if (panel.visible) root.read() }

  function read() {
    var script = ""
    for (var i = 0; i < cities.length; i++)
      script += "TZ=" + Util.shq(cities[i].zone) + " date '+%H:%M|%a|%z|%Y%m%d'; "
    script += "date '+%Y%m%d'"
    reader.command = ["sh", "-c", script]
    reader.running = true
  }

  Process {
    id: reader
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n")
        var today = lines[lines.length - 1]
        var out = []
        for (var i = 0; i < root.cities.length && i < lines.length - 1; i++) {
          var f = lines[i].split("|")
          var rel = f[3] > today ? "Tomorrow" : (f[3] < today ? "Yesterday" : "Today")
          var z = f[2] || ""
          out.push({ name: root.cities[i].name || root.cities[i].zone, time: f[0], day: rel + ", " + f[1], offset: "UTC" + z.slice(0, 3) + (z.slice(3) !== "00" ? ":" + z.slice(3) : "") })
        }
        root.rows = out
      }
    }
  }

  Timer { interval: 20000; running: panel.visible; repeat: true; onTriggered: root.read() }

  Popout {
    id: panel
    anchorItem: root
    panelWidth: 300

    PanelHeader { title: "World clock" }

    Repeater {
      model: root.rows
      ListRow {
        required property var modelData
        interactive: false
        title: modelData.name
        subtitle: modelData.day + " · " + modelData.offset
        detail: modelData.time
      }
    }
  }
}
