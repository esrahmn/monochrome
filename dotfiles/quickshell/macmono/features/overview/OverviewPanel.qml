import "../../core"
import QtQuick
import Quickshell

// The workspace overview, as a body of the island: it hangs from the bar like every other panel,
// so the bar and the overview are one shape. No window of its own.
// Arrows / H J K L move between workspaces, Tab cycles windows, Enter opens, 1-9 jump, Esc closes.
Item {
    id: root

    property string panelScreen: ""
    readonly property bool shown: Sys.activePanel === "overview" && Sys.activePanelScreen === panelScreen
    readonly property var screenInfo: Quickshell.screens.find((s) => {
        return s.name === panelScreen;
    }) ?? Quickshell.screens[0] ?? null
    readonly property real fit: root.screenInfo === null ? 1 : Math.min(1, (root.screenInfo.width - Theme.space32 * 5) / Math.max(1, ov.implicitWidth), (root.screenInfo.height - Theme.barHeight - Theme.space32 * 3) / Math.max(1, ov.implicitHeight))
    property bool settled: false

    implicitWidth: ov.implicitWidth * root.fit
    implicitHeight: ov.implicitHeight * root.fit
    onShownChanged: {
        settled = false;
        if (shown) {
            settleTimer.restart();
            Sys.refreshHypr();
            ov.pruneShots();
            ov.resetCursor();
            forceActiveFocus();
        } else {
            settleTimer.stop();
        }
    }
    Component.onCompleted: {
        if (shown)
            settleTimer.restart();

        ov.resetCursor();
        forceActiveFocus();
    }
    focus: true
    Keys.onPressed: (e) => {
        if (ov.handleKey(e))
            e.accepted = true;

    }

    Timer {
        id: settleTimer

        interval: 160
        onTriggered: root.settled = true
    }

    Item {
        id: stage

        width: ov.implicitWidth
        height: ov.implicitHeight
        x: (root.width - width * root.fit) / 2
        scale: root.fit
        transformOrigin: Item.TopLeft

        Overview {
            id: ov

            anchors.fill: parent
            screenInfo: root.screenInfo
            live: root.shown && root.settled && !Sys.capturing
            onActivated: (cmd) => {
                return Sys.closeAndDispatch(cmd);
            }
        }

    }

}
