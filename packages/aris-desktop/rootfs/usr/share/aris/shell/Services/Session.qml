pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

// Session-wide state and power actions.
Singleton {
  id: root

  // The live ISO: no password, so nothing may lock.
  readonly property bool live: Quickshell.env("ARIS_LIVE") === "1" || liveMarker.loaded
  readonly property string user: Quickshell.env("USER") || ""

  property bool stayAwake: false

  // Launcher and menus live in shell.qml; widgets ask for them through here.
  signal launcherRequested()
  signal menuRequested(string name)

  // Set by the lock screen; the bar's power panel calls lock().
  property var locker: null

  function lock() {
    if (root.locker) root.locker.lock()
  }

  function suspend() { Quickshell.execDetached(["systemctl", "suspend"]) }
  function reboot() { Quickshell.execDetached(["systemctl", "reboot"]) }
  function poweroff() { Quickshell.execDetached(["systemctl", "poweroff"]) }
  function logout() { Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]) }

  FileView {
    id: liveMarker
    property bool loaded: false
    path: "/etc/aris-live"
    printErrors: false
    onLoaded: loaded = true
  }
}
