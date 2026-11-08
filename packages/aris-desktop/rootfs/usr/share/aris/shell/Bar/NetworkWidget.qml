import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

BarButton {
  id: root
  property var options: ({})
  property var bar: null
  property string asking: "" // SSID waiting for a password

  height: bar ? bar.size : 26
  icon: Network.icon()
  active: panel.visible
  onClicked: {
    panel.toggle()
    if (panel.visible) { root.asking = ""; Network.error = ""; Network.refresh() }
  }

  function pick(net) {
    if (net.active) { Network.disconnect(); return }
    if (net.known || !net.secure) { root.asking = ""; Network.connect(net.ssid, ""); return }
    root.asking = net.ssid
    password.text = ""
    password.forceActiveFocus()
  }

  Popout {
    id: panel
    anchorItem: root
    panelWidth: 320

    PanelHeader {
      title: "Network"
      subtitle: Network.summary()
      Switch {
        visible: Network.hasWifi
        checked: Network.wifiEnabled
        onToggled: Network.setWifi(!Network.wifiEnabled)
      }
    }

    Flickable {
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(nets.implicitHeight, 300)
      visible: Network.hasWifi && Network.wifiEnabled
      contentHeight: nets.implicitHeight
      clip: true
      ColumnLayout {
        id: nets
        width: parent.width
        spacing: 2
        Repeater {
          model: Network.networks
          ListRow {
            required property var modelData
            icon: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(modelData.signal / 20))]
            title: modelData.ssid
            subtitle: modelData.active ? "Connected" : (modelData.known ? "Saved" : (modelData.secure ? "Secured" : "Open"))
            detail: modelData.secure ? "󰌾" : ""
            selected: modelData.active || root.asking === modelData.ssid
            onClicked: root.pick(modelData)
          }
        }
      }
    }

    // Password for a new secured network.
    RowLayout {
      visible: root.asking !== ""
      Layout.fillWidth: true
      spacing: 6
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 30
        radius: 7
        color: Theme.raised
        border.width: 1
        border.color: password.activeFocus ? Theme.soft : Theme.line
        TextInput {
          id: password
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          color: Theme.fg
          selectionColor: Theme.grey
          font.family: Theme.font
          font.pixelSize: Theme.fontSize
          clip: true
          onAccepted: { Network.connect(root.asking, text); root.asking = "" }
          Label { visible: !parent.text; text: "Password for " + root.asking; dim: true; anchors.verticalCenter: parent.verticalCenter; width: parent.width }
        }
      }
      TextButton { text: "Join"; primary: true; onClicked: { Network.connect(root.asking, password.text); root.asking = "" } }
    }

    Label {
      visible: Network.error !== "" || Network.busy
      text: Network.busy ? "Working…" : Network.error
      dim: true
      wrapMode: Text.Wrap
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      TextButton { visible: Network.hasWifi && Network.wifiEnabled; icon: "󰑐"; text: "Scan"; onClicked: Network.rescan() }
      Item { Layout.fillWidth: true }
      TextButton { text: "Settings"; onClicked: { panel.close(); Quickshell.execDetached(["nm-connection-editor"]) } }
    }
  }
}
