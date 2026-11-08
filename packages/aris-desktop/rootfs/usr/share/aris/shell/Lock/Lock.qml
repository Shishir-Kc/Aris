import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.Common
import qs.Services
import qs.Widgets

// The lock screen: ext-session-lock surfaces on every screen and PAM
// (/etc/pam.d/aris-lock). If the shell dies while locked the compositor keeps
// the session locked; restart the shell and lock again to get back in.
Scope {
  id: root

  property bool locked: false
  property string password: ""
  property string status: ""
  property bool checking: false
  property string wallpaper: "/usr/share/aris/wallpapers/aris-default.png"

  function lock() {
    if (Session.live) return
    wallpaperReader.running = true
    root.password = ""
    root.status = ""
    root.locked = true
  }

  function submit() {
    if (root.checking || root.password === "") return
    root.checking = true
    root.status = ""
    pam.start()
  }

  PamContext {
    id: pam
    config: "aris-lock"
    user: Session.user

    onPamMessage: {
      if (pam.responseRequired) pam.respond(root.password)
      else if (pam.messageIsError) root.status = pam.message
    }

    onCompleted: function(result) {
      root.checking = false
      if (result === PamResult.Success) {
        root.locked = false
        root.password = ""
        root.status = ""
      } else {
        root.password = ""
        root.status = result === PamResult.MaxTries ? "Too many attempts" : "Wrong password"
      }
    }

    onError: function() {
      root.checking = false
      root.password = ""
      root.status = "Authentication error"
    }
  }

  Process {
    id: wallpaperReader
    command: ["sh", "-c", "f=$(readlink -f -- \"${XDG_CONFIG_HOME:-$HOME/.config}/aris/wallpaper\" 2>/dev/null); [ -f \"$f\" ] && echo \"$f\" || echo /usr/share/aris/wallpapers/aris-default.png"]
    stdout: StdioCollector { onStreamFinished: root.wallpaper = text.trim() }
  }

  WlSessionLock {
    locked: root.locked

    WlSessionLockSurface {
      id: surface
      color: Theme.base

      property date now: new Date()
      Timer { interval: 1000; running: root.locked; repeat: true; onTriggered: surface.now = new Date() }

      Image {
        anchors.fill: parent
        source: "file://" + root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
      Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.base, 0.72) }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        Label {
          text: Qt.formatDateTime(surface.now, "HH:mm")
          size: 96
          font.weight: Font.Light
          Layout.alignment: Qt.AlignHCenter
        }
        Label {
          text: Qt.formatDateTime(surface.now, "dddd, d MMMM")
          size: 18
          color: Theme.soft
          Layout.alignment: Qt.AlignHCenter
          Layout.bottomMargin: 36
        }

        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          width: 64; height: 64; radius: 32
          color: Theme.raised
          border.width: 1
          border.color: Theme.line
          Glyph { anchors.centerIn: parent; text: "󰀄"; size: 28 }
        }
        Label {
          text: Session.user
          color: Theme.soft
          Layout.alignment: Qt.AlignHCenter
          Layout.bottomMargin: 10
        }

        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          width: 300
          height: 44
          radius: 22
          color: Theme.alpha(Theme.surface, 0.9)
          border.width: 1
          border.color: input.activeFocus ? Theme.soft : Theme.line

          TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            focus: true
            enabled: !root.checking
            echoMode: TextInput.Password
            passwordCharacter: "•"
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 16
            text: root.password
            onTextChanged: root.password = text
            onAccepted: root.submit()
            Keys.onEscapePressed: root.password = ""
            Component.onCompleted: forceActiveFocus()
          }
          Label {
            anchors.centerIn: parent
            visible: input.text === ""
            text: root.checking ? "Checking…" : "Password"
            dim: true
          }
        }

        Label {
          text: root.status
          color: Theme.soft
          Layout.alignment: Qt.AlignHCenter
          Layout.preferredHeight: 20
        }
      }
    }
  }
}
