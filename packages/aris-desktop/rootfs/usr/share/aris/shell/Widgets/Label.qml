import QtQuick
import qs.Common

Text {
  property real size: Theme.fontSize
  property bool dim: false
  color: dim ? Theme.muted : Theme.fg
  font.family: Theme.font
  font.pixelSize: size
  verticalAlignment: Text.AlignVCenter
  elide: Text.ElideRight
}
