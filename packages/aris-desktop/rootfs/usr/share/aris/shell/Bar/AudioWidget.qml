import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

// Scroll for volume, middle click mutes, click for outputs and apps.
BarButton {
  id: root
  property var options: ({})
  property var bar: null

  height: bar ? bar.size : 26
  icon: Audio.icon(Audio.volume, Audio.muted)
  active: panel.visible
  onClicked: function(button) {
    if (button === Qt.MiddleButton) Audio.toggleMute()
    else if (button === Qt.RightButton) Quickshell.execDetached(["pavucontrol"])
    else panel.toggle()
  }
  onWheel: function(steps) { Audio.step(steps) }

  Popout {
    id: panel
    anchorItem: root
    panelWidth: 340

    PanelHeader { title: "Sound"; subtitle: Audio.shortName(Audio.sink) }

    Slider {
      icon: Audio.icon(Audio.volume, Audio.muted)
      value: Audio.muted ? 0 : Audio.volume
      onMoved: function(v) { Audio.setVolume(v) }
      onIconClicked: Audio.toggleMute()
    }

    Label { visible: Audio.sinks.length > 1; text: "Output"; dim: true }
    Repeater {
      model: Audio.sinks.length > 1 ? Audio.sinks : []
      ListRow {
        required property var modelData
        icon: "󰓃"
        title: Audio.shortName(modelData)
        subtitle: modelData.nickname ? Audio.nodeName(modelData) : ""
        selected: modelData === Audio.sink
        onClicked: Audio.setDefault(modelData)
      }
    }

    Label { visible: Audio.streams.length > 0; text: "Apps"; dim: true }
    Repeater {
      model: Audio.streams
      ColumnLayout {
        required property var modelData
        Layout.fillWidth: true
        spacing: 0
        Label { text: Audio.nodeName(modelData); Layout.fillWidth: true }
        Slider {
          icon: Audio.icon(modelData.audio.volume, modelData.audio.muted)
          value: modelData.audio.muted ? 0 : modelData.audio.volume
          onMoved: function(v) { modelData.audio.muted = false; modelData.audio.volume = v }
          onIconClicked: modelData.audio.muted = !modelData.audio.muted
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      TextButton {
        icon: Audio.micMuted ? "󰍭" : "󰍬"
        text: Audio.micMuted ? "Mic off" : "Mic on"
        checked: Audio.micMuted
        onClicked: if (Audio.source && Audio.source.audio) Audio.source.audio.muted = !Audio.source.audio.muted
      }
      Item { Layout.fillWidth: true }
      TextButton { text: "Mixer"; onClicked: { panel.close(); Quickshell.execDetached(["pavucontrol"]) } }
    }
  }
}
