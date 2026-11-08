import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Common
import qs.Services
import qs.Widgets

// Volume and brightness pop-up, bottom centre of the focused screen.
PanelWindow {
  id: root

  property string glyph: ""
  property real level: 0
  property string label: ""
  property bool armed: false

  function show(g, v, text) {
    root.glyph = g
    root.level = v
    root.label = text
    root.visible = true
    hideTimer.restart()
  }

  screen: {
    var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    var all = Quickshell.screens
    for (var i = 0; i < all.length; i++) if (all[i].name === name) return all[i]
    return all[0]
  }
  visible: false
  anchors.bottom: true
  margins.bottom: 80
  exclusionMode: ExclusionMode.Ignore
  implicitWidth: 260
  implicitHeight: 52
  color: "transparent"
  WlrLayershell.namespace: "aris-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  // Never steal clicks.
  mask: Region {}

  Timer { id: hideTimer; interval: 1500; onTriggered: root.visible = false }
  // PipeWire reports the starting volume once at login; don't pop up for it.
  Timer { interval: 2000; running: true; onTriggered: root.armed = true }

  Connections {
    target: Audio.sink ? Audio.sink.audio : null
    function onVolumesChanged() { if (root.armed) root.show(Audio.icon(Audio.volume, Audio.muted), Audio.volume, Math.round(Audio.volume * 100) + "%") }
    function onMutedChanged() { if (root.armed) root.show(Audio.icon(Audio.volume, Audio.muted), Audio.muted ? 0 : Audio.volume, Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%") }
  }

  Connections {
    target: Brightness
    function onOsdRequested() { root.show(Brightness.icon(Brightness.value), Brightness.value, Math.round(Brightness.value * 100) + "%") }
  }

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: Theme.alpha(Theme.surface, 0.96)
    border.width: 1
    border.color: Theme.line

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 18
      anchors.rightMargin: 18
      spacing: 12
      Glyph { text: root.glyph; size: 18; Layout.preferredWidth: 20 }
      Rectangle {
        Layout.fillWidth: true
        height: 6
        radius: 3
        color: Theme.line
        Rectangle {
          width: parent.width * Util.clamp(root.level, 0, 1)
          height: parent.height
          radius: 3
          color: Theme.fg
          Behavior on width { NumberAnimation { duration: Theme.animFast } }
        }
      }
      Label { text: root.label; dim: true; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
    }
  }
}
