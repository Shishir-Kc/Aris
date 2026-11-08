import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

// One searchable list for apps, the power menu, keybindings and clipboard
// history. open(mode) fills it; Escape or a click outside closes it.
PanelWindow {
  id: root

  property string mode: ""
  property var items: [] // { title, subtitle, glyph, iconName, run: function }
  property string query: ""
  property bool loading: false
  readonly property var shownItems: filter(mode === "apps" ? appItems : items, query)

  readonly property var modes: ({
    apps: { prompt: "Apps", load: loadApps },
    power: { prompt: "Power", load: loadPower },
    keybinds: { prompt: "Keys", load: loadKeybinds },
    clipboard: { prompt: "Clipboard", load: loadClipboard }
  })

  function open(name) {
    var m = root.modes[name]
    if (!m) { console.warn("aris-shell: unknown menu '" + name + "'"); return }
    root.query = ""
    root.items = []
    root.mode = name
    root.loading = name === "keybinds" || name === "clipboard"
    search.text = ""
    list.currentIndex = 0
    m.load()
    search.forceActiveFocus()
  }

  function toggle(name) {
    if (root.mode === name) close()
    else open(name)
  }

  function close() {
    root.mode = ""
    root.items = []
  }

  function activate(item) {
    if (!item) return
    root.close()
    if (item.run) item.run()
  }

  // Prefix > word start > substring > in-order letters.
  function score(text, q) {
    var t = String(text || "").toLowerCase()
    if (t === "") return 0
    if (t.indexOf(q) === 0) return 100
    var i = t.indexOf(q)
    if (i > 0) return /[\s\-_.]/.test(t[i - 1]) ? 80 : 60
    var k = 0
    for (var j = 0; j < t.length && k < q.length; j++) if (t[j] === q[k]) k++
    return k === q.length ? 10 : 0
  }

  function filter(all, q) {
    q = String(q || "").trim().toLowerCase()
    if (q === "") return all
    var out = []
    for (var i = 0; i < all.length; i++) {
      var it = all[i]
      var s = Math.max(score(it.title, q), score(it.subtitle, q) * 0.5, score(it.keywords, q) * 0.4)
      if (s > 0) out.push({ item: it, s: s })
    }
    out.sort(function(a, b) { return (b.s - a.s) || a.item.title.localeCompare(b.item.title) })
    return out.map(function(o) { return o.item })
  }

  // Desktop entries load in the background, so this stays a live binding
  // rather than a snapshot taken when the launcher opens.
  readonly property var appItems: {
    var term = Config.launcher.terminal || "kitty"
    return DesktopEntries.applications.values.filter(function(e) { return !e.noDisplay }).map(function(e) {
      return {
        title: e.name,
        subtitle: e.genericName || e.comment || "",
        keywords: e.keywords + " " + e.categories + " " + e.id,
        iconName: e.icon,
        run: function() {
          if (e.runInTerminal) Quickshell.execDetached([term, "-e", "sh", "-c", e.execString.replace(/%[fFuUdDnNickvm]/g, "")])
          else e.execute()
        }
      }
    }).sort(function(a, b) { return a.title.localeCompare(b.title) })
  }

  function loadApps() {}

  function loadPower() {
    var list = []
    if (!Session.live) list.push({ title: "Lock", glyph: "󰌾", run: Session.lock })
    list.push({ title: "Suspend", glyph: "󰤄", run: Session.suspend })
    list.push({ title: "Log out", glyph: "󰍃", run: Session.logout })
    list.push({ title: "Reboot", glyph: "󰜉", run: Session.reboot })
    list.push({ title: "Shut down", glyph: "󰐥", run: Session.poweroff })
    root.items = list
  }

  function loadKeybinds() {
    binds.running = true
  }

  function loadClipboard() {
    clips.running = true
  }

  // modmask bits: SHIFT 1, CAPS 2, CTRL 4, ALT 8, MOD2 16, MOD3 32, SUPER 64, MOD5 128
  function combo(b) {
    var parts = []
    if (b.modmask & 64) parts.push("SUPER")
    if (b.modmask & 4) parts.push("CTRL")
    if (b.modmask & 8) parts.push("ALT")
    if (b.modmask & 1) parts.push("SHIFT")
    var names = { "mouse:272": "Left drag", "mouse:273": "Right drag", "mouse_down": "Scroll down", "mouse_up": "Scroll up", "grave": "`", "slash": "/" }
    parts.push(names[b.key] || b.key)
    return parts.join(" + ")
  }

  Process {
    id: binds
    command: ["hyprctl", "binds", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (root.mode !== "keybinds") return
        root.loading = false
        try {
          var seen = {}, out = []
          var all = JSON.parse(text)
          for (var i = 0; i < all.length; i++) {
            var b = all[i]
            if (!b.has_description || (b.submap && b.submap !== "")) continue
            var c = root.combo(b)
            if (seen[c + b.description]) continue
            seen[c + b.description] = true
            out.push({ title: b.description, subtitle: c, glyph: "󰌌" })
          }
          root.items = out
        } catch (e) {}
      }
    }
  }

  Process {
    id: clips
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (root.mode !== "clipboard") return
        root.loading = false
        var lines = text.split("\n").filter(function(l) { return l !== "" })
        root.items = lines.map(function(line) {
          var preview = line.replace(/^\d+\t/, "")
          var image = /^\[\[ binary data/.test(preview)
          return {
            title: preview.replace(/\s+/g, " ").slice(0, 200),
            glyph: image ? "󰋩" : "󰅍",
            run: function() { Util.sh("printf '%s' " + Util.shq(line) + " | cliphist decode | wl-copy") }
          }
        })
      }
    }
  }

  screen: {
    var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    var all = Quickshell.screens
    for (var i = 0; i < all.length; i++) if (all[i].name === name) return all[i]
    return all[0]
  }
  visible: mode !== ""
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"
  WlrLayershell.namespace: "aris-launcher"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: box
    width: Math.min(600, parent.width - 40)
    height: column.implicitHeight + 24
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(parent.height * 0.18)
    radius: Theme.radius + 2
    color: Theme.alpha(Theme.surface, 0.97)
    border.width: 1
    border.color: Theme.line

    // Swallow clicks so they don't reach the backdrop.
    MouseArea { anchors.fill: parent }

    ColumnLayout {
      id: column
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 10

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 42
        radius: Theme.radius
        color: Theme.raised
        border.width: 1
        border.color: Theme.line

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          spacing: 10
          Label { text: (root.modes[root.mode] ? root.modes[root.mode].prompt : "") + "  ❯"; dim: true }
          TextInput {
            id: search
            Layout.fillWidth: true
            color: Theme.fg
            selectionColor: Theme.grey
            selectedTextColor: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 2
            clip: true
            onTextChanged: { root.query = text; list.currentIndex = 0 }
            Keys.onPressed: function(e) {
              var down = e.key === Qt.Key_Down || e.key === Qt.Key_Tab || (e.key === Qt.Key_J && (e.modifiers & Qt.ControlModifier)) || (e.key === Qt.Key_N && (e.modifiers & Qt.ControlModifier))
              var up = e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (e.key === Qt.Key_K && (e.modifiers & Qt.ControlModifier)) || (e.key === Qt.Key_P && (e.modifiers & Qt.ControlModifier))
              if (e.key === Qt.Key_Escape) { root.close(); e.accepted = true }
              else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.activate(root.shownItems[list.currentIndex]); e.accepted = true }
              else if (down) { list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1); e.accepted = true }
              else if (up) { list.currentIndex = Math.max(0, list.currentIndex - 1); e.accepted = true }
              else if (e.key === Qt.Key_PageDown) { list.currentIndex = Math.min(list.count - 1, list.currentIndex + 8); e.accepted = true }
              else if (e.key === Qt.Key_PageUp) { list.currentIndex = Math.max(0, list.currentIndex - 8); e.accepted = true }
            }
          }
        }
      }

      ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 46 * 9)
        visible: count > 0
        clip: true
        model: root.shownItems
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0
        currentIndex: 0

        delegate: Rectangle {
          id: row
          required property var modelData
          required property int index
          width: list.width
          height: 46
          radius: 8
          color: ListView.isCurrentItem ? Theme.alpha(Theme.fg, 0.12) : "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            Item {
              id: iconBox
              readonly property string path: row.modelData.iconName ? Quickshell.iconPath(row.modelData.iconName, true) : ""
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              IconImage {
                anchors.fill: parent
                visible: iconBox.path !== ""
                source: iconBox.path
              }
              Glyph {
                anchors.centerIn: parent
                visible: iconBox.path === ""
                text: row.modelData.glyph || (row.modelData.iconName ? "󰣆" : "")
                size: 18
              }
            }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1
              Label { text: row.modelData.title; Layout.fillWidth: true }
              Label { visible: !!row.modelData.subtitle; text: row.modelData.subtitle || ""; dim: true; size: Theme.fontSize - 1; Layout.fillWidth: true }
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: list.currentIndex = row.index
            onClicked: root.activate(row.modelData)
          }
        }
      }

      Label {
        visible: list.count === 0
        text: root.loading ? "Loading…" : ((root.mode === "apps" ? root.appItems : root.items).length === 0 ? "Nothing here" : "No matches")
        dim: true
        Layout.leftMargin: 6
        Layout.bottomMargin: 4
      }
    }
  }
}
