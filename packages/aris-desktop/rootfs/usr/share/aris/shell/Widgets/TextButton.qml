import QtQuick
import qs.Common

// Pill button. `primary` fills it milky white.
Rectangle {
  id: root
  property string text: ""
  property string icon: ""
  property bool primary: false
  property bool checked: false
  signal clicked()

  implicitHeight: 28
  implicitWidth: row.implicitWidth + 22
  radius: 7
  color: primary || checked ? Theme.fg : (mouse.containsMouse ? Theme.alpha(Theme.fg, 0.12) : Theme.alpha(Theme.fg, 0.05))
  border.width: primary || checked ? 0 : 1
  border.color: Theme.line
  Behavior on color { ColorAnimation { duration: Theme.animFast } }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6
    Glyph { visible: root.icon !== ""; text: root.icon; size: Theme.fontSize + 1; color: root.primary || root.checked ? Theme.base : Theme.fg; anchors.verticalCenter: parent.verticalCenter }
    Label { visible: root.text !== ""; text: root.text; color: root.primary || root.checked ? Theme.base : Theme.fg; anchors.verticalCenter: parent.verticalCenter }
  }
  MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
