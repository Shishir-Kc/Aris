import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

// One bar per screen. Widgets and their order come from Config.bar.layout;
// ids may carry a prefix ("aris.clock", "omarchy.clock"), which is ignored.
PanelWindow {
  id: bar

  required property var modelData
  screen: modelData

  readonly property bool atBottom: Config.bar.position === "bottom"
  readonly property int size: Config.bar.size || 20
  readonly property var layout: Config.bar.layout || ({})

  readonly property var files: ({
    "workspaces": "WorkspacesWidget.qml",
    "tray": "TrayWidget.qml",
    "bluetooth": "BluetoothWidget.qml",
    "indicators": "IndicatorsWidget.qml",
    "keyboard-layout": "KeyboardWidget.qml",
    "clock": "ClockWidget.qml",
    "world-clock": "WorldClockWidget.qml",
    "elsewhen": "WorldClockWidget.qml",
    "weather": "WeatherWidget.qml",
    "system-update": "UpdatesWidget.qml",
    "network": "NetworkWidget.qml",
    "audio": "AudioWidget.qml",
    "brightness": "BrightnessWidget.qml",
    "monitor": "BrightnessWidget.qml",
    "power": "PowerWidget.qml",
    "launcher": "LauncherWidget.qml",
    "menu": "LauncherWidget.qml",
    "active-window": "WindowTitleWidget.qml"
  })

  function fileFor(id) {
    var name = String(id || "").replace(/^.*\./, "")
    return bar.files[name] || ""
  }

  anchors {
    top: !bar.atBottom
    bottom: bar.atBottom
    left: true
    right: true
  }
  implicitHeight: size
  color: Config.bar.transparent ? "transparent" : Theme.alpha(Theme.base, 0.92)

  WlrLayershell.namespace: "aris-bar"
  WlrLayershell.layer: WlrLayer.Top

  IdleInhibitor {
    window: bar
    enabled: Session.stayAwake
  }

  component Section: RowLayout {
    property var items: []
    height: bar.size
    spacing: 0

    Repeater {
      model: items
      delegate: Loader {
        required property var modelData
        Layout.fillHeight: true
        visible: status === Loader.Ready && item.shown !== false
        Component.onCompleted: {
          var file = bar.fileFor(modelData.id)
          if (file === "") {
            console.warn("aris-shell: unknown bar widget '" + modelData.id + "'")
            return
          }
          setSource(file, { options: modelData, bar: bar })
        }
      }
    }
  }

  Section {
    anchors.left: parent.left
    anchors.leftMargin: 6
    items: bar.layout.left || []
  }

  Section {
    anchors.horizontalCenter: parent.horizontalCenter
    items: bar.layout.center || []
  }

  Section {
    anchors.right: parent.right
    anchors.rightMargin: 6
    items: bar.layout.right || []
  }
}
