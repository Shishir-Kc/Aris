pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Common

// Default output/input and per-app streams, straight from PipeWire.
Singleton {
  id: root

  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property PwNode source: Pipewire.defaultAudioSource
  readonly property bool ready: sink !== null && sink.ready && sink.audio !== null
  readonly property real volume: ready ? sink.audio.volume : 0
  readonly property bool muted: ready ? sink.audio.muted : false
  readonly property bool micMuted: source !== null && source.ready && source.audio !== null ? source.audio.muted : false

  readonly property var sinks: Pipewire.nodes.values.filter(function(n) { return n.isSink && !n.isStream && n.audio !== null })
  readonly property var streams: Pipewire.nodes.values.filter(function(n) { return n.isStream && !n.isSink && n.audio !== null })

  PwObjectTracker {
    objects: [root.sink, root.source].concat(root.sinks).concat(root.streams).filter(function(n) { return n !== null })
  }

  function nodeName(n) {
    if (!n) return ""
    var p = n.properties || {}
    return n.description || n.nickname || p["application.name"] || p["media.name"] || n.name
  }

  // "Speaker", "HDMI 1": short enough to tell outputs apart.
  function shortName(n) {
    if (!n) return ""
    return n.nickname || nodeName(n)
  }

  function setVolume(v) {
    if (!ready) return
    sink.audio.muted = false
    sink.audio.volume = Util.clamp(v, 0, 1)
  }

  function step(steps) {
    setVolume(Math.round((volume + 0.05 * steps) * 20) / 20)
  }

  function toggleMute() {
    if (ready) sink.audio.muted = !sink.audio.muted
  }

  function setDefault(node) {
    Pipewire.preferredDefaultAudioSink = node
  }

  function icon(vol, mute) {
    if (mute || vol <= 0) return "󰝟"
    if (vol < 0.34) return "󰕿"
    if (vol < 0.67) return "󰖀"
    return "󰕾"
  }
}
