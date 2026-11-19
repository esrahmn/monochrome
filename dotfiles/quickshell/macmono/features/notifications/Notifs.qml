import QtQuick
import QtQml
import Quickshell
import Quickshell.Services.Notifications
import "../../core"

// Receives notifications. It has no window: the island draws them (NotifToasts).
// This owns the server AND how long each toast lives, so a notification can never get stuck
// on screen even if nothing is drawing it.
Scope {
    id: root

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        onNotification: (n) => {
            if (Sys.notifIsMuted(n.appName)) {
                Qt.callLater(() => { try { n.dismiss(); } catch (e) {} });
                return;
            }
            Sys.pushNotif(n);
            if (!Sys.dnd && !Sys.calendarOpen) n.tracked = true;
        }
    }

    // One timer per tracked notification. Paused while the island is hovered.
    Instantiator {
        model: server.trackedNotifications
        delegate: Timer {
            required property var modelData
            interval: Settings.notifDefaultTimeoutMs
            running: !Sys.toastHover
            onTriggered: { try { modelData.expire(); } catch (e) {} }
        }
    }

    // The island shows a toast whenever this is above zero. Driven by the model's own signals.
    Connections {
        target: server.trackedNotifications
        function onObjectInsertedPost(object, index) { root.syncCount(); }
        function onObjectRemovedPost(object, index) { root.syncCount(); }
    }

    // Plain array of the live notifications, for NotifToasts to draw.
    function syncCount() {
        const v = server.trackedNotifications.values;
        const items = [];
        for (let i = 0; i < v.length; i++)
            items.push(v[i]);
        Sys.toastItems = items;
        Sys.toastCount = items.length;
    }

    Component.onCompleted: {
        Sys.toastModel = server.trackedNotifications;
        syncCount();
    }
}
