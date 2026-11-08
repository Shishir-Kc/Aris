import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets

// Left click swaps to formatAlt, right click opens the calendar.
BarButton {
  id: root
  property var options: ({})
  property var bar: null
  property date now: new Date()
  property bool alt: false

  height: bar ? bar.size : 26
  text: Util.formatDate(now, alt && options.formatAlt ? options.formatAlt : (options.format || "dddd HH:mm"))
  active: panel.visible
  onClicked: function(button) {
    if (button === Qt.RightButton) panel.toggle()
    else alt = !alt
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  Popout {
    id: panel
    anchorItem: root
    panelWidth: 280
    onVisibleChanged: if (visible) cal.month = new Date(root.now.getFullYear(), root.now.getMonth(), 1)

    PanelHeader {
      title: Qt.formatDateTime(root.now, "dddd")
      subtitle: Util.formatDate(root.now, root.options.formatAlt || "d MMMM yyyy")
    }

    Item {
      id: cal
      property date month: new Date()
      readonly property int firstWeekday: (new Date(month.getFullYear(), month.getMonth(), 1).getDay() + 6) % 7
      readonly property int daysInMonth: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()

      Layout.fillWidth: true
      implicitHeight: calCol.implicitHeight

      function shift(n) { month = new Date(month.getFullYear(), month.getMonth() + n, 1) }

      ColumnLayout {
        id: calCol
        width: parent.width
        spacing: 6

        RowLayout {
          Layout.fillWidth: true
          Glyph { text: "󰅁"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cal.shift(-1) } }
          Label { text: Qt.formatDateTime(cal.month, "MMMM yyyy"); Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
          Glyph { text: "󰅂"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cal.shift(1) } }
        }

        Grid {
          columns: 7
          Layout.alignment: Qt.AlignHCenter
          spacing: 2

          Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            Label { required property string modelData; text: modelData; dim: true; width: 34; horizontalAlignment: Text.AlignHCenter }
          }

          Repeater {
            model: 42
            Rectangle {
              required property int index
              readonly property int day: index - cal.firstWeekday + 1
              readonly property bool inMonth: day >= 1 && day <= cal.daysInMonth
              readonly property bool today: inMonth && day === root.now.getDate()
                && cal.month.getMonth() === root.now.getMonth() && cal.month.getFullYear() === root.now.getFullYear()
              visible: index < 35 || cal.firstWeekday + cal.daysInMonth > 35
              width: 34; height: 26; radius: 6
              color: today ? Theme.fg : "transparent"
              Label {
                anchors.centerIn: parent
                text: parent.inMonth ? parent.day : ""
                color: parent.today ? Theme.base : Theme.fg
                font.weight: parent.today ? Font.Bold : Font.Normal
              }
            }
          }
        }
      }
    }
  }
}
