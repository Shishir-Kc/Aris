import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Common
import qs.Services
import qs.Widgets

// Battery (or a power glyph on desktops). Click for power profiles,
// do-not-disturb, stay-awake and the session actions.
BarButton {
  id: root
  property var options: ({})
  property var bar: null

  readonly property var battery: UPower.displayDevice
  readonly property bool hasBattery: battery !== null && battery.isLaptopBattery && battery.isPresent
  readonly property real level: hasBattery ? battery.percentage : 0
  readonly property bool charging: hasBattery && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge)
  property bool warned: false

  function batteryGlyph() {
    if (charging) return "󰂄"
    var icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    return icons[Math.min(9, Math.max(0, Math.floor(level * 10 - 0.001)))]
  }

  height: bar ? bar.size : 26
  icon: hasBattery ? batteryGlyph() : "󰐥"
  text: hasBattery && options.showPercentage ? Math.round(level * 100) + "%" : ""
  active: panel.visible
  onClicked: panel.toggle()

  // One warning per discharge below 10%.
  onLevelChanged: {
    if (!hasBattery || charging) { warned = false; return }
    if (level <= 0.10 && !warned) {
      warned = true
      Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Battery", "Battery low", Math.round(level * 100) + "% left — plug in soon."])
    }
  }

  component Action: ColumnLayout {
    property string glyph
    property string label
    signal activated()
    spacing: 4
    Layout.fillWidth: true
    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      width: 44; height: 44; radius: 22
      color: area.containsMouse ? Theme.fg : Theme.raised
      border.width: 1
      border.color: Theme.line
      Glyph { anchors.centerIn: parent; text: glyph; size: 18; color: area.containsMouse ? Theme.base : Theme.fg }
      MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: activated() }
    }
    Label { text: label; dim: true; size: Theme.fontSize - 1; Layout.alignment: Qt.AlignHCenter }
  }

  Popout {
    id: panel
    anchorItem: root
    panelWidth: 330

    PanelHeader {
      title: root.hasBattery ? Math.round(root.level * 100) + "%" : "Power"
      subtitle: {
        if (!root.hasBattery) return Session.user
        if (root.battery.state === UPowerDeviceState.FullyCharged) return "Fully charged"
        if (root.charging) return "Charging" + (root.battery.timeToFull > 0 ? " · full in " + Util.durationText(root.battery.timeToFull) : "")
        return "On battery" + (root.battery.timeToEmpty > 0 ? " · " + Util.durationText(root.battery.timeToEmpty) + " left" : "")
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 6
      TextButton { Layout.fillWidth: true; icon: "󰌪"; text: "Saver"; checked: PowerProfiles.profile === PowerProfile.PowerSaver; onClicked: PowerProfiles.profile = PowerProfile.PowerSaver }
      TextButton { Layout.fillWidth: true; icon: "󰗑"; text: "Balanced"; checked: PowerProfiles.profile === PowerProfile.Balanced; onClicked: PowerProfiles.profile = PowerProfile.Balanced }
      TextButton { Layout.fillWidth: true; visible: PowerProfiles.hasPerformanceProfile; icon: "󰓅"; text: "Perf"; checked: PowerProfiles.profile === PowerProfile.Performance; onClicked: PowerProfiles.profile = PowerProfile.Performance }
    }

    RowLayout {
      Layout.fillWidth: true
      Glyph { text: "󰂛" }
      Label { text: "Do not disturb"; Layout.fillWidth: true }
      Switch { checked: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
    }
    RowLayout {
      Layout.fillWidth: true
      Glyph { text: "󰅶" }
      Label { text: "Stay awake"; Layout.fillWidth: true }
      Switch { checked: Session.stayAwake; onToggled: Session.stayAwake = !Session.stayAwake }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.line }

    RowLayout {
      Layout.fillWidth: true
      Action { visible: !Session.live; glyph: "󰌾"; label: "Lock"; onActivated: { panel.close(); Session.lock() } }
      Action { glyph: "󰤄"; label: "Suspend"; onActivated: { panel.close(); Session.suspend() } }
      Action { glyph: "󰍃"; label: "Log out"; onActivated: Session.logout() }
      Action { glyph: "󰜉"; label: "Reboot"; onActivated: Session.reboot() }
      Action { glyph: "󰐥"; label: "Shut down"; onActivated: Session.poweroff() }
    }
  }
}
