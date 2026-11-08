import QtQuick
import QtQuick.Layouts
import qs.Common

// 0..1 slider. `moved(value)` fires while dragging or clicking.
Item {
  id: root
  property real value: 0
  property string icon: ""
  signal moved(real value)
  signal iconClicked()

  Layout.fillWidth: true
  implicitHeight: 28

  RowLayout {
    anchors.fill: parent
    spacing: 10

    Glyph {
      visible: root.icon !== ""
      text: root.icon
      Layout.preferredWidth: 18
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.iconClicked() }
    }

    Item {
      id: track
      Layout.fillWidth: true
      Layout.fillHeight: true

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.line
        Rectangle {
          width: Math.max(height, parent.width * Util.clamp(root.value, 0, 1))
          height: parent.height
          radius: 3
          color: Theme.fg
        }
      }
      Rectangle {
        x: (track.width - width) * Util.clamp(root.value, 0, 1)
        anchors.verticalCenter: parent.verticalCenter
        width: 14; height: 14; radius: 7
        color: Theme.fg
        border.width: 2
        border.color: Theme.surface
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function update(x) { root.moved(Util.clamp(x / width, 0, 1)) }
        onPressed: function(e) { update(e.x) }
        onPositionChanged: function(e) { if (pressed) update(e.x) }
      }
    }

    Label {
      text: Math.round(Util.clamp(root.value, 0, 1.5) * 100) + "%"
      dim: true
      Layout.preferredWidth: 38
      horizontalAlignment: Text.AlignRight
    }
  }
}
