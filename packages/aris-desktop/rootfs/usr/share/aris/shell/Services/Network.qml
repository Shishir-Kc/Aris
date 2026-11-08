pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

// NetworkManager state through nmcli. `nmcli monitor` tells us when to re-read.
Singleton {
  id: root

  property string kind: "none" // wifi | ethernet | none
  property string connection: ""
  property int strength: 0
  property bool wifiEnabled: true
  property bool hasWifi: false
  property var networks: [] // { ssid, signal, secure, active, known }
  property var known: []
  property bool busy: false
  property string error: ""

  function icon() {
    if (kind === "ethernet") return "󰈀"
    if (kind === "wifi") return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(strength / 20))]
    if (hasWifi && !wifiEnabled) return "󰤮"
    return "󰤭"
  }

  function summary() {
    if (kind === "ethernet") return "Wired" + (connection ? " · " + connection : "")
    if (kind === "wifi") return connection + " · " + strength + "%"
    if (hasWifi && !wifiEnabled) return "Wi-Fi off"
    return "Offline"
  }

  // nmcli -t escapes ':' and '\' inside fields.
  function fields(line) {
    var out = [], cur = ""
    for (var i = 0; i < line.length; i++) {
      var c = line[i]
      if (c === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
      if (c === ":") { out.push(cur); cur = ""; continue }
      cur += c
    }
    out.push(cur)
    return out
  }

  function parse(text) {
    var parts = text.split("\n---\n")
    var devices = (parts[0] || "").split("\n")
    var nextKind = "none", nextConn = "", wifiDev = false
    for (var i = 0; i < devices.length; i++) {
      var d = fields(devices[i])
      if (d.length < 3) continue
      if (d[0] === "wifi") wifiDev = true
      if (d[1] !== "connected") continue
      if (d[0] === "ethernet" && nextKind !== "ethernet") { nextKind = "ethernet"; nextConn = d[2] }
      else if (d[0] === "wifi" && nextKind === "none") { nextKind = "wifi"; nextConn = d[2] }
    }

    var saved = []
    var conns = (parts[3] || "").split("\n")
    for (var c = 0; c < conns.length; c++) {
      var cf = fields(conns[c])
      if (cf.length >= 2 && cf[1].indexOf("wireless") !== -1) saved.push(cf[0])
    }

    var seen = {}, list = [], activeSignal = 0
    var wifi = (parts[1] || "").split("\n")
    for (var w = 0; w < wifi.length; w++) {
      var f = fields(wifi[w])
      if (f.length < 4 || f[1] === "") continue
      var active = f[0] === "yes"
      var sig = parseInt(f[2], 10) || 0
      if (active) activeSignal = sig
      if (seen[f[1]] !== undefined) {
        var prev = list[seen[f[1]]]
        prev.active = prev.active || active
        prev.signal = Math.max(prev.signal, sig)
        continue
      }
      seen[f[1]] = list.length
      list.push({ ssid: f[1], signal: sig, secure: f[3] !== "" && f[3] !== "--", active: active, known: saved.indexOf(f[1]) !== -1 })
    }
    list.sort(function(a, b) { return (b.active - a.active) || (b.known - a.known) || (b.signal - a.signal) })

    root.hasWifi = wifiDev
    root.wifiEnabled = (parts[2] || "").trim() === "enabled"
    root.kind = nextKind
    root.connection = nextConn
    root.strength = activeSignal
    root.known = saved
    root.networks = list
  }

  function refresh() {
    if (!reader.running) reader.running = true
  }

  function rescan() {
    root.busy = true
    run(["nmcli", "device", "wifi", "rescan"])
  }

  function setWifi(on) {
    run(["nmcli", "radio", "wifi", on ? "on" : "off"])
  }

  function connect(ssid, password) {
    root.busy = true
    root.error = ""
    if (root.known.indexOf(ssid) !== -1 && !password) run(["nmcli", "connection", "up", "id", ssid])
    else if (password) run(["nmcli", "device", "wifi", "connect", ssid, "password", password])
    else run(["nmcli", "device", "wifi", "connect", ssid])
  }

  function disconnect() {
    if (root.connection) run(["nmcli", "connection", "down", "id", root.connection])
  }

  function run(cmd) {
    action.command = cmd
    action.running = true
  }

  Process {
    id: reader
    command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device; echo ---; nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null; echo ---; nmcli radio wifi; echo ---; nmcli -t -f NAME,TYPE connection show"]
    stdout: StdioCollector { onStreamFinished: root.parse(text) }
  }

  Process {
    id: action
    stderr: StdioCollector { id: actionErr }
    onExited: function(code) {
      root.busy = false
      if (code !== 0) root.error = actionErr.text.trim().replace(/^Error: /, "")
      root.refresh()
    }
  }

  // Re-read on any NetworkManager change, batched.
  Process {
    id: monitor
    command: ["nmcli", "monitor"]
    running: true
    stdout: SplitParser { onRead: settle.restart() }
    onExited: restartMonitor.start()
  }
  Timer { id: restartMonitor; interval: 5000; onTriggered: monitor.running = true }
  Timer { id: settle; interval: 400; onTriggered: root.refresh() }
  // Signal strength isn't an event.
  Timer { interval: 30000; running: true; repeat: true; onTriggered: root.refresh() }

  Component.onCompleted: refresh()
}
