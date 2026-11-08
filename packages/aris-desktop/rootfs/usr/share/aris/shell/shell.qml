//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

// Aris shell: wallpaper, bar, notifications, OSD, launcher/menus and lock
// screen in one Quickshell process. Started by aris-shell; settings live in
// ~/.config/aris/shell.json (see defaults.json for every key).
//
// IPC (`aris-shell ipc call <target> <function> [args]`):
//   launcher toggle            menu open <apps|power|keybinds|clipboard>
//   lock lock                  notifications hideAll | dismissAll | restore | toggleDnd
//   osd brightness             wallpaper reload          session toggleStayAwake

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Background
import qs.Bar
import qs.Notifications
import qs.Osd
import qs.Launcher
import qs.Lock

ShellRoot {
  id: shell

  Variants {
    id: wallpapers
    model: Quickshell.screens
    Background {}
  }

  Variants {
    model: Quickshell.screens
    Bar {}
  }

  Toasts {}
  Osd {}
  Launcher { id: launcher }
  Lock { id: locker }

  Component.onCompleted: Session.locker = locker

  Connections {
    target: Session
    function onLauncherRequested() { launcher.toggle("apps") }
    function onMenuRequested(name) { launcher.toggle(name) }
  }

  IpcHandler {
    target: "launcher"
    function toggle(): void { launcher.toggle("apps") }
  }

  IpcHandler {
    target: "menu"
    function open(name: string): void { launcher.toggle(name) }
    function close(): void { launcher.close() }
  }

  IpcHandler {
    target: "lock"
    function lock(): void { locker.lock() }
    function isLocked(): bool { return locker.locked }
  }

  IpcHandler {
    target: "notifications"
    function hideAll(): void { Notifs.hideAll() }
    function dismissAll(): void { Notifs.dismissAll() }
    function restore(): void { Notifs.restoreLast() }
    function toggleDnd(): void { Notifs.dnd = !Notifs.dnd }
  }

  IpcHandler {
    target: "osd"
    function brightness(): void { Brightness.refresh(true) }
  }

  IpcHandler {
    target: "wallpaper"
    function reload(): void {
      var all = wallpapers.instances
      for (var i = 0; i < all.length; i++) all[i].reload()
    }
  }

  IpcHandler {
    target: "session"
    function toggleStayAwake(): void { Session.stayAwake = !Session.stayAwake }
  }
}
