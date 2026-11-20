import QtQuick
import QtQml
import Quickshell
import Quickshell.Services.Notifications
import "../../core"

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

    Instantiator {
        model: server.trackedNotifications
        delegate: Timer {
            required property var modelData
            interval: Settings.notifDefaultTimeoutMs
            running: !Sys.toastHover
            onTriggered: { try { modelData.expire(); } catch (e) {} }
        }
    }

    Connections {
        target: server.trackedNotifications
        function onObjectInsertedPost(object, index) { root.syncCount(); }
        function onObjectRemovedPost(object, index) { root.syncCount(); }
    }

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
