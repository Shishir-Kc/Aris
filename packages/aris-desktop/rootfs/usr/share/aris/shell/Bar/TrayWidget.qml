import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Common

// Status-notifier icons. Left click activates, right click opens the menu.
Item {
  id: root
  property var options: ({})
  property var bar: null
  readonly property bool shown: SystemTray.items.values.length > 0

  implicitWidth: row.implicitWidth + 8
  implicitHeight: bar ? bar.size : 26

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 4

    Repeater {
      model: SystemTray.items.values

      Item {
        id: slot
        required property var modelData
        width: 22
        height: root.height

        Rectangle {
          anchors.fill: parent
          anchors.topMargin: 3
          anchors.bottomMargin: 3
          radius: 6
          color: mouse.containsMouse ? Theme.alpha(Theme.fg, 0.08) : "transparent"
        }

        IconImage {
          anchors.centerIn: parent
          implicitSize: 15
          source: slot.modelData.icon
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onClicked: function(e) {
            var item = slot.modelData
            var openMenu = function() {
              var p = slot.mapToItem(null, 0, root.bar.atBottom ? 0 : slot.height + 4)
              item.display(root.bar, p.x, p.y)
            }
            if (e.button === Qt.MiddleButton) item.secondaryActivate()
            else if (e.button === Qt.RightButton) { if (item.hasMenu) openMenu() }
            else if (item.onlyMenu && item.hasMenu) openMenu()
            else item.activate()
          }
          onWheel: function(e) { slot.modelData.scroll(e.angleDelta.y, false) }
        }
      }
    }
  }
}
