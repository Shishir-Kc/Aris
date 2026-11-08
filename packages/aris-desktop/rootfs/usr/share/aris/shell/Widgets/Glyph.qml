import QtQuick
import qs.Common

// A Nerd Font icon.
Text {
  property real size: Theme.fontSize + 2
  color: Theme.fg
  font.family: Theme.font
  font.pixelSize: size
  verticalAlignment: Text.AlignVCenter
  horizontalAlignment: Text.AlignHCenter
}
