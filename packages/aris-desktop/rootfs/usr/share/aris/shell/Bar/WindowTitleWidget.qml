import QtQuick
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

Label {
  id: root
  property var options: ({})
  property var bar: null
  readonly property bool shown: text !== ""
  height: bar ? bar.size : 26
  leftPadding: 8
  rightPadding: 8
  width: Math.min(implicitWidth, options.maxWidth || 420)
  dim: true
  text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
}
