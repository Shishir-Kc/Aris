import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets

// Pending pacman updates (checkupdates, from pacman-contrib). Hidden at zero.
// Click to update in a terminal.
BarButton {
  id: root
  property var options: ({})
  property var bar: null
  property int count: 0
  readonly property bool shown: count > 0

  height: bar ? bar.size : 26
  icon: "󰚰"
  text: String(count)
  onClicked: {
    var term = Config.launcher.terminal || "kitty"
    var cmd = term === "kitty" ? [term, "--class", "aris.float"] : [term]
    Quickshell.execDetached(cmd.concat(["-e", "sh", "-c",
      "sudo pacman -Syu; echo; printf 'Done. Press Enter to close.'; read -r _"]))
    root.count = 0
    recheck.restart()
  }

  Process {
    id: checker
    command: ["sh", "-c", "command -v checkupdates >/dev/null && checkupdates 2>/dev/null | wc -l || echo 0"]
    stdout: StdioCollector { onStreamFinished: root.count = parseInt(text.trim(), 10) || 0 }
  }

  // First check a little after login, then hourly.
  Timer { interval: 90 * 1000; running: true; onTriggered: checker.running = true }
  Timer { interval: 60 * 60 * 1000; running: true; repeat: true; onTriggered: checker.running = true }
  Timer { id: recheck; interval: 5 * 60 * 1000; onTriggered: checker.running = true }
}
