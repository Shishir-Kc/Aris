import QtQuick
import QtQuick.Layouts
import qs.Common

// A clickable row: icon, title, subtitle, right-hand detail.
Rectangle {
  id: root
  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property string detail: ""
  property bool selected: false
  property bool interactive: true
  signal clicked(int button)

  Layout.fillWidth: true
  implicitHeight: Math.max(34, col.implicitHeight + 12)
  radius: 7
  color: selected ? Theme.alpha(Theme.fg, 0.14) : (mouse.containsMouse && interactive ? Theme.alpha(Theme.fg, 0.07) : "transparent")
  Behavior on color { ColorAnimation { duration: Theme.animFast } }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    spacing: 10
    Glyph { visible: root.icon !== ""; text: root.icon; Layout.preferredWidth: 18 }
    ColumnLayout {
      id: col
      Layout.fillWidth: true
      spacing: 0
      Label { text: root.title; Layout.fillWidth: true }
      Label { visible: root.subtitle !== ""; text: root.subtitle; dim: true; size: Theme.fontSize - 1; Layout.fillWidth: true }
    }
    Label { visible: root.detail !== ""; text: root.detail; dim: true }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(e) { root.clicked(e.button) }
  }
}
