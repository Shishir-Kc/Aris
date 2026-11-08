import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

// Laptop backlight; hidden without one. Scroll or click for a slider.
BarButton {
  id: root
  property var options: ({})
  property var bar: null
  readonly property bool shown: Brightness.available

  height: bar ? bar.size : 26
  icon: Brightness.icon(Brightness.value)
  active: panel.visible
  onClicked: { panel.toggle(); if (panel.visible) Brightness.refresh(false) }
  onWheel: function(steps) { Brightness.step(steps) }

  Popout {
    id: panel
    anchorItem: root
    panelWidth: 300
    PanelHeader { title: "Display" }
    Slider {
      icon: Brightness.icon(Brightness.value)
      value: Brightness.value
      onMoved: function(v) { Brightness.set(v) }
    }
  }
}
