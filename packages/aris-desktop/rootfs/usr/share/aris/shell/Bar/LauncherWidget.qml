import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

// The Aris mark; opens the app launcher.
BarButton {
  id: root
  property var options: ({})
  property var bar: null
  height: bar ? bar.size : 26
  icon: "✦"
  onClicked: function(button) {
    if (button === Qt.RightButton) Session.menuRequested("keybinds")
    else Session.launcherRequested()
  }
}
