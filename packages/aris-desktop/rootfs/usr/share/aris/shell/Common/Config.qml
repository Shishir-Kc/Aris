pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shell settings: package defaults (defaults.json next to shell.qml) with the
// user's ~/.config/aris/shell.json laid over them, one section at a time. The
// user file is watched, so edits apply on save.
Singleton {
  id: root

  readonly property string userPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/aris/shell.json"

  property var defaults: ({})
  property var user: ({})

  readonly property var bar: section("bar")
  readonly property var notifications: section("notifications")
  readonly property var launcher: section("launcher")

  function section(name) {
    var out = {}
    var base = root.defaults[name] || {}
    var mine = root.user[name] || {}
    for (var k in base) out[k] = base[k]
    for (var m in mine) out[m] = mine[m]
    return out
  }

  function parse(text, path) {
    try {
      var value = JSON.parse(text)
      return (value && typeof value === "object") ? value : {}
    } catch (e) {
      console.warn("aris-shell: ignoring " + path + ": " + e)
      return {}
    }
  }

  FileView {
    path: Quickshell.shellPath("defaults.json")
    blockLoading: true
    onLoaded: root.defaults = root.parse(text(), path)
  }

  FileView {
    path: root.userPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.user = root.parse(text(), path)
    onLoadFailed: root.user = ({})
  }
}
