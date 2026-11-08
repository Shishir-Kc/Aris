import QtQuick
import qs.Common

Rectangle {
  id: root
  property bool checked: false
  signal toggled()

  implicitWidth: 36
  implicitHeight: 20
  radius: 10
  color: checked ? Theme.fg : Theme.line
  Behavior on color { ColorAnimation { duration: Theme.animFast } }

  Rectangle {
    width: 14; height: 14; radius: 7
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? parent.width - width - 3 : 3
    color: root.checked ? Theme.base : Theme.soft
    Behavior on x { NumberAnimation { duration: Theme.animFast } }
  }
  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled() }
}
