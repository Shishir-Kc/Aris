import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.Common
import qs.Services
import qs.Widgets

// Notification toasts, top right of the focused screen, newest on top.
PanelWindow {
  id: root

  screen: {
    var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    var all = Quickshell.screens
    for (var i = 0; i < all.length; i++) if (all[i].name === name) return all[i]
    return all[0]
  }

  visible: Notifs.toasts.length > 0
  anchors {
    top: Config.bar.position !== "bottom"
    bottom: Config.bar.position === "bottom"
    right: true
  }
  margins {
    top: Theme.gap
    bottom: Theme.gap
    right: Theme.gap
  }
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0
  implicitWidth: 380
  implicitHeight: stack.implicitHeight
  color: "transparent"

  WlrLayershell.namespace: "aris-notifications"
  WlrLayershell.layer: WlrLayer.Overlay

  ColumnLayout {
    id: stack
    width: parent.width
    spacing: 8

    Repeater {
      model: Notifs.toasts

      Rectangle {
        id: toast
        required property var modelData
        readonly property var n: modelData
        readonly property bool critical: n.urgency === NotificationUrgency.Critical
        readonly property string imageSource: n.image !== "" ? n.image : (n.appIcon !== "" ? Quickshell.iconPath(n.appIcon, true) : "")

        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + 24
        radius: Theme.radius
        color: Theme.alpha(Theme.surface, 0.96)
        border.width: critical ? 2 : 1
        border.color: critical ? Theme.fg : Theme.line

        Timer {
          interval: Notifs.timeoutFor(toast.n)
          running: interval > 0 && !hover.containsMouse
          onTriggered: Notifs.hide(toast.n)
        }

        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(e) {
            if (e.button === Qt.RightButton) { toast.n.dismiss(); return }
            var def = toast.n.actions.filter(function(a) { return a.identifier === "default" })[0]
            if (def) def.invoke()
            else Notifs.hide(toast.n)
          }
        }

        RowLayout {
          id: body
          x: 12
          y: 12
          width: parent.width - 24
          spacing: 12

          IconImage {
            visible: toast.imageSource !== ""
            source: toast.imageSource
            implicitSize: 40
            Layout.alignment: Qt.AlignTop
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
              Layout.fillWidth: true
              Label { text: toast.n.appName || "Notification"; dim: true; size: Theme.fontSize - 1; Layout.fillWidth: true }
              Glyph {
                text: "󰅖"
                size: Theme.fontSize
                color: Theme.muted
                MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: toast.n.dismiss() }
              }
            }
            Label {
              text: toast.n.summary
              font.weight: Font.DemiBold
              wrapMode: Text.Wrap
              maximumLineCount: 2
              Layout.fillWidth: true
            }
            Text {
              visible: text !== ""
              text: toast.n.body
              textFormat: Text.StyledText
              color: Theme.soft
              font.family: Theme.font
              font.pixelSize: Theme.fontSize
              wrapMode: Text.Wrap
              maximumLineCount: 5
              elide: Text.ElideRight
              linkColor: Theme.fg
              onLinkActivated: function(link) { Qt.openUrlExternally(link) }
              Layout.fillWidth: true
            }
            Flow {
              visible: toast.n.actions.filter(function(a) { return a.identifier !== "default" }).length > 0
              Layout.fillWidth: true
              Layout.topMargin: 4
              spacing: 6
              Repeater {
                model: toast.n.actions.filter(function(a) { return a.identifier !== "default" })
                TextButton {
                  required property var modelData
                  text: modelData.text
                  onClicked: modelData.invoke()
                }
              }
            }
          }
        }
      }
    }
  }
}
