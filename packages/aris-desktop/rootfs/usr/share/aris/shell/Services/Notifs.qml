pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Common

// The notification daemon. Toasts that time out are only hidden, so they stay
// in the history for "restore"; the close button dismisses them for good.
Singleton {
  id: root

  property bool dnd: false
  property var toasts: []
  readonly property int historyLimit: 50
  readonly property int maxVisible: Config.notifications.maxVisible || 5

  function show(n) {
    if (!n) return
    var list = root.toasts.filter(function(x) { return x !== n })
    list.unshift(n)
    root.toasts = list.slice(0, root.maxVisible)
  }

  function hide(n) {
    root.toasts = root.toasts.filter(function(x) { return x !== n })
  }

  function hideAll() {
    root.toasts = []
  }

  function dismissAll() {
    var all = server.trackedNotifications.values.slice()
    root.toasts = []
    for (var i = 0; i < all.length; i++) all[i].dismiss()
  }

  // Bring back the newest notification that isn't on screen.
  function restoreLast() {
    var all = server.trackedNotifications.values
    for (var i = all.length - 1; i >= 0; i--) {
      if (root.toasts.indexOf(all[i]) === -1) {
        root.show(all[i])
        return
      }
    }
  }

  // Milliseconds; the spec allows -1 (server default) and 0 (never).
  function timeoutFor(n) {
    if (n.urgency === NotificationUrgency.Critical) return 0
    var t = Number(n.expireTimeout)
    if (!isFinite(t) || t < 0) return Config.notifications.timeout || 5000
    if (t === 0) return 0
    return t < 100 ? t * 1000 : t
  }

  NotificationServer {
    id: server
    keepOnReload: false
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true
    persistenceSupported: true

    onNotification: function(n) {
      n.tracked = true
      n.closed.connect(function() { root.hide(n) })

      var all = server.trackedNotifications.values
      if (all.length > root.historyLimit) all[0].dismiss()

      if (root.dnd && n.urgency !== NotificationUrgency.Critical) return
      root.show(n)
    }
  }
}
