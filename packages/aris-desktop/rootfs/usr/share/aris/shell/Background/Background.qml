import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common

// The wallpaper, one per screen. aris-wallpaper points
// ~/.config/aris/wallpaper at an image and asks us to reload.
PanelWindow {
  id: root

  required property var modelData
  screen: modelData

  readonly property string statePath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/aris/wallpaper"
  readonly property string fallback: "/usr/share/aris/wallpapers/aris-default.png"
  property string source: ""

  function reload() {
    resolver.running = true
  }

  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  color: Theme.base
  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.namespace: "aris-wallpaper"

  Process {
    id: resolver
    command: ["sh", "-c", "f=$(readlink -f -- \"$1\" 2>/dev/null); [ -f \"$f\" ] && echo \"$f\" || echo \"$2\"", "sh", root.statePath, root.fallback]
    stdout: StdioCollector { onStreamFinished: root.source = text.trim() }
  }

  Image {
    anchors.fill: parent
    source: root.source !== "" ? "file://" + root.source : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: root.width * root.devicePixelRatio
    sourceSize.height: root.height * root.devicePixelRatio
  }

  Component.onCompleted: reload()
}
