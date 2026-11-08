import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

// Workspaces 1-5 always, plus any other that exists. The one this screen
// shows is a square, empty ones are dimmed.
Item {
  id: root
  property var options: ({})
  property var bar: null

  readonly property var monitor: bar ? Hyprland.monitorFor(bar.screen) : Hyprland.focusedMonitor
  readonly property int shownId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1
  readonly property int persistent: options.persistent !== undefined ? options.persistent : 5

  readonly property var ids: {
    var list = []
    for (var i = 1; i <= persistent; i++) list.push(i)
    var all = Hyprland.workspaces.values
    for (var j = 0; j < all.length; j++) {
      var id = all[j].id
      if (id > 0 && list.indexOf(id) === -1) list.push(id)
    }
    return list.sort(function(a, b) { return a - b })
  }

  function workspace(id) {
    var all = Hyprland.workspaces.values
    for (var i = 0; i < all.length; i++) if (all[i].id === id) return all[i]
    return null
  }

  function focus(target) {
    Hyprland.dispatch("hl.dsp.focus({ workspace = " + Util.lua(String(target)) + " })")
  }

  implicitWidth: row.implicitWidth
  implicitHeight: bar ? bar.size : 26

  Row {
    id: row
    height: parent.height

    Repeater {
      model: root.ids

      BarButton {
        required property int modelData
        readonly property var ws: root.workspace(modelData)
        readonly property bool shown: modelData === root.shownId
        readonly property bool occupied: ws !== null && ws.toplevels.values.length > 0

        height: row.height
        fixedWidth: 22
        padding: 4
        icon: shown ? "󱓻" : ""
        text: shown ? "" : (modelData === 10 ? "0" : String(modelData))
        contentOpacity: shown || occupied ? 1 : 0.45
        onClicked: root.focus(modelData)
        onWheel: function(steps) { root.focus(steps > 0 ? "e-1" : "e+1") }

        Rectangle {
          visible: parent.ws !== null && parent.ws.urgent
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 3
          width: 10; height: 2; radius: 1
          color: Theme.fg
        }
      }
    }
  }

  // Hyprland credits every switch to the focused monitor; ask for the truth.
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var n = String(event.name)
      if (n === "moveworkspacev2" || n === "renameworkspace" || n === "focusedmonv2") {
        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
      }
    }
  }
}
