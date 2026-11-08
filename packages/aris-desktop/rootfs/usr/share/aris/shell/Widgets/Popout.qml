import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common

// A panel that drops out of a bar item. Clicking anywhere outside closes it.
PopupWindow {
  id: root

  required property Item anchorItem
  property int panelWidth: 320
  property int pad: 14
  default property alias content: body.data

  function toggle() { root.visible = !root.visible }
  function close() { root.visible = false }

  anchor.item: anchorItem
  anchor.edges: Config.bar.position === "bottom" ? Edges.Top : Edges.Bottom
  anchor.gravity: Config.bar.position === "bottom" ? Edges.Top : Edges.Bottom
  anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.FlipY
  anchor.margins.top: 6
  anchor.margins.bottom: 6
  grabFocus: true
  visible: false
  color: "transparent"
  implicitWidth: panelWidth
  implicitHeight: body.implicitHeight + pad * 2

  Rectangle {
    anchors.fill: parent
    radius: Theme.radius
    color: Theme.alpha(Theme.surface, 0.97)
    border.width: 1
    border.color: Theme.line

    ColumnLayout {
      id: body
      x: root.pad
      y: root.pad
      width: parent.width - root.pad * 2
      spacing: 8
    }
  }
}
