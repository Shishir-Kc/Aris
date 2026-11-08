import QtQuick
import QtQuick.Layouts
import qs.Common

// Panel title row with an optional trailing control.
RowLayout {
  id: root
  property string title: ""
  property string subtitle: ""
  default property alias trailing: tail.data

  Layout.fillWidth: true
  spacing: 8

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 1
    Label { text: root.title; size: Theme.fontSize + 2; font.weight: Font.DemiBold; Layout.fillWidth: true }
    Label { visible: root.subtitle !== ""; text: root.subtitle; dim: true; Layout.fillWidth: true }
  }
  Row { id: tail; spacing: 6 }
}
