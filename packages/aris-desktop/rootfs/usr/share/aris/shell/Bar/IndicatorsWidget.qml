import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

// Shows a state only while it's on: do-not-disturb and stay-awake.
// Click one to turn it off. Both are also in the power panel.
Item {
  id: root
  property var options: ({})
  property var bar: null
  readonly property bool shown: Notifs.dnd || Session.stayAwake

  implicitWidth: row.implicitWidth
  implicitHeight: bar ? bar.size : 26

  Row {
    id: row
    height: parent.height
    BarButton {
      visible: Notifs.dnd
      height: row.height
      icon: "󰂛"
      onClicked: Notifs.dnd = false
    }
    BarButton {
      visible: Session.stayAwake
      height: row.height
      icon: "󰅶"
      onClicked: Session.stayAwake = false
    }
  }
}
