import QtQuick
import qs.Common

// A bar item: glyph and/or text with a hover fill. Emits clicked(button) and
// wheel(steps) where steps > 0 means scrolled up.
Item {
  id: root

  property string icon: ""
  property string text: ""
  property string tooltip: ""
  property bool active: false
  property real contentOpacity: 1
  property int padding: 7
  property int fixedWidth: 0
  property alias hovered: mouse.containsMouse

  signal clicked(int button)
  signal wheel(int steps)

  implicitHeight: parent ? parent.height : 26
  implicitWidth: fixedWidth > 0 ? fixedWidth : row.implicitWidth + padding * 2

  property real _wheelAcc: 0

  Rectangle {
    anchors.fill: parent
    anchors.topMargin: 3
    anchors.bottomMargin: 3
    radius: 6
    color: root.active ? Theme.alpha(Theme.fg, 0.16) : (mouse.containsMouse ? Theme.alpha(Theme.fg, 0.08) : "transparent")
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 5
    opacity: root.contentOpacity

    Glyph {
      visible: root.icon !== ""
      text: root.icon
      anchors.verticalCenter: parent.verticalCenter
    }
    Label {
      visible: root.text !== ""
      text: root.text
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(e) { root.clicked(e.button) }
    onWheel: function(e) {
      root._wheelAcc += e.angleDelta.y
      var steps = Math.trunc(root._wheelAcc / 120)
      if (steps !== 0) {
        root._wheelAcc -= steps * 120
        root.wheel(steps)
      }
    }
  }
}
