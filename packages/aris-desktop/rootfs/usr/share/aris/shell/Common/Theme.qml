pragma Singleton
import QtQuick

// The Aris palette: shades of black, grey and a warm milky white. Every
// surface in the shell takes its colours from here, so a change in this file
// re-themes the bar, panels, notifications, launcher and lock screen at once.
QtObject {
  // Blacks, darkest first.
  readonly property color base: "#0b0b0b"
  readonly property color surface: "#131313"
  readonly property color raised: "#1b1b1b"
  readonly property color line: "#2a2a2a"

  // Greys.
  readonly property color grey: "#4a4a4a"
  readonly property color muted: "#8a8a8a"
  readonly property color soft: "#bcb8b0"

  // Milky white: text, icons and the accent.
  readonly property color fg: "#ece8e1"

  readonly property string font: "JetBrainsMono Nerd Font"
  readonly property string uiFont: "Inter"
  readonly property int fontSize: 12

  // Matches Hyprland's decoration.rounding and gaps in aris/look.lua.
  readonly property int radius: 10
  readonly property int gap: 10

  readonly property int animFast: 120
  readonly property int anim: 200

  function alpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }
}
