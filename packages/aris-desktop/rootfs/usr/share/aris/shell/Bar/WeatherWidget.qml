import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

BarButton {
  id: root
  property var options: ({})
  property var bar: null
  readonly property bool shown: Weather.ready

  height: bar ? bar.size : 26
  icon: Weather.glyph
  text: Weather.temp
  active: panel.visible
  onClicked: function(button) {
    if (button === Qt.RightButton) Weather.refresh()
    else panel.toggle()
  }
  onOptionsChanged: {
    Weather.imperial = options.units === "imperial"
    Weather.location = options.location || ""
  }

  Popout {
    id: panel
    anchorItem: root
    panelWidth: 300

    PanelHeader { title: Weather.place || "Weather"; subtitle: Weather.desc }

    RowLayout {
      Layout.fillWidth: true
      spacing: 14
      Glyph { text: Weather.glyph; size: 40 }
      ColumnLayout {
        spacing: 2
        Label { text: Weather.temp; size: 24; font.weight: Font.DemiBold }
        Label { text: "Feels like " + Weather.feels; dim: true }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Label { text: "󰖎  " + Weather.humidity; dim: true; Layout.fillWidth: true }
      Label { text: "󰖝  " + Weather.wind; dim: true }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }

    Repeater {
      model: Weather.days
      ListRow {
        required property var modelData
        required property int index
        interactive: false
        icon: modelData.glyph
        title: index === 0 ? "Today" : Qt.formatDate(new Date(modelData.date + "T12:00:00"), "dddd")
        detail: modelData.hi + " / " + modelData.lo
      }
    }
  }
}
