import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.Common
import qs.Widgets

// Hidden without an adapter. Click for power, scan and devices.
BarButton {
  id: root
  property var options: ({})
  property var bar: null

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool shown: adapter !== null
  readonly property var devices: {
    if (!adapter) return []
    return adapter.devices.values.filter(function(d) { return d.paired || d.connected || d.name !== "" })
      .sort(function(a, b) { return (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name) })
  }
  readonly property int connectedCount: devices.filter(function(d) { return d.connected }).length

  height: bar ? bar.size : 26
  icon: !adapter || !adapter.enabled ? "󰂲" : (connectedCount > 0 ? "󰂱" : "󰂯")
  contentOpacity: adapter && adapter.enabled ? 1 : 0.6
  active: panel.visible
  onClicked: function(button) {
    if (button === Qt.RightButton) Quickshell.execDetached(["blueman-manager"])
    else panel.toggle()
  }

  function glyphFor(d) {
    var i = String(d.icon || "")
    if (i.indexOf("headset") !== -1 || i.indexOf("headphone") !== -1) return "󰋋"
    if (i.indexOf("audio") !== -1) return "󰓃"
    if (i.indexOf("mouse") !== -1) return "󰍽"
    if (i.indexOf("keyboard") !== -1) return "󰌌"
    if (i.indexOf("phone") !== -1) return "󰏲"
    if (i.indexOf("joystick") !== -1 || i.indexOf("gaming") !== -1) return "󰊴"
    return "󰂯"
  }

  Popout {
    id: panel
    anchorItem: root
    panelWidth: 320
    onVisibleChanged: if (!visible && root.adapter && root.adapter.discovering) root.adapter.discovering = false

    PanelHeader {
      title: "Bluetooth"
      subtitle: !root.adapter ? "" : (!root.adapter.enabled ? "Off" : (root.connectedCount > 0 ? root.connectedCount + " connected" : "On"))
      Switch {
        checked: root.adapter !== null && root.adapter.enabled
        onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
      }
    }

    Flickable {
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(list.implicitHeight, 300)
      visible: root.adapter !== null && root.adapter.enabled
      contentHeight: list.implicitHeight
      clip: true
      ColumnLayout {
        id: list
        width: parent.width
        spacing: 2
        Repeater {
          model: root.devices
          ListRow {
            required property var modelData
            icon: root.glyphFor(modelData)
            title: modelData.name || modelData.address
            subtitle: modelData.pairing ? "Pairing…"
              : modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
              : modelData.connected ? "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
              : modelData.paired ? "Paired" : "Available"
            selected: modelData.connected
            onClicked: function(button) {
              var d = modelData
              if (button === Qt.RightButton && d.paired) { d.forget(); return }
              if (d.connected) d.disconnect()
              else if (!d.paired) { d.trusted = true; d.pair() }
              else d.connect()
            }
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      TextButton {
        visible: root.adapter !== null && root.adapter.enabled
        icon: "󰑐"
        text: root.adapter && root.adapter.discovering ? "Scanning…" : "Scan"
        checked: root.adapter !== null && root.adapter.discovering
        onClicked: root.adapter.discovering = !root.adapter.discovering
      }
      Item { Layout.fillWidth: true }
      TextButton { text: "Settings"; onClicked: { panel.close(); Quickshell.execDetached(["blueman-manager"]) } }
    }
  }
}
