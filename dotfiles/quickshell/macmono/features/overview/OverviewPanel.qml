import QtQuick
import Quickshell
import "../../core"
import "../../shared/components"

Item {
    id: root
    anchors.fill: parent
    property string panelScreen: ""
    readonly property bool shown: Sys.activePanel === "overview" && Sys.activePanelScreen === panelScreen
    readonly property var screenInfo: Quickshell.screens.find((s) => s.name === panelScreen)
        ?? Quickshell.screens[0] ?? null
    readonly property int stageTop: Math.max(176, Math.round(height * 0.19))
    readonly property int stageBottom: 86
    property bool settled: false

    focus: true
    onShownChanged: {
        if (shown) {
            settled = false;
            searchInput.text = "";
            settleTimer.restart();
            Sys.refreshHypr();
            overview.pruneShots();
            overview.resetCursor();
            Qt.callLater(() => searchInput.forceActiveFocus());
        } else {
            settleTimer.stop();
        }
    }
    Component.onCompleted: {
        if (shown) {
            settleTimer.restart();
            Qt.callLater(() => searchInput.forceActiveFocus());
        }
    }
    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Escape) {
            Sys.overviewOpen = false;
            e.accepted = true;
        } else if (overview.handleKey(e)) {
            e.accepted = true;
        }
    }

    Timer {
        id: settleTimer
        interval: 160
        onTriggered: root.settled = true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.015, 0.02, 0.025, 0.60)
        Behavior on color { ColorAnimation { duration: Theme.durBase } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: Sys.overviewOpen = false
    }

    Column {
        id: header
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: Math.max(34, Math.round(root.height * 0.045)) }
        spacing: Theme.space16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Overview"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 30
            font.weight: Font.DemiBold
        }

        Rectangle {
            id: searchBox
            width: Math.min(640, root.width - Theme.space32 * 4)
            height: 58
            radius: Theme.radiusCard + 4
            color: Qt.rgba(0.10, 0.11, 0.12, 0.92)
            border.width: searchInput.activeFocus ? Theme.borderThin : 1
            border.color: searchInput.activeFocus ? Theme.lineFocus : Theme.line

            Glyph {
                id: searchGlyph
                anchors { left: parent.left; leftMargin: Theme.space24; verticalCenter: parent.verticalCenter }
                width: Theme.iconMd
                height: Theme.iconMd
                name: "search"
                color: searchInput.text !== "" ? Theme.text : Theme.dim
            }

            TextInput {
                id: searchInput
                anchors { left: searchGlyph.right; leftMargin: Theme.space12; right: parent.right; rightMargin: Theme.space24; verticalCenter: parent.verticalCenter }
                color: Theme.text
                selectionColor: Theme.tileHover
                selectedTextColor: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontLg
                clip: true
                selectByMouse: true
                onTextChanged: overview.query = text
                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_Escape) {
                        if (text !== "") text = "";
                        else Sys.overviewOpen = false;
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        if (text !== "") overview.activateFirstMatch();
                        else overview.activateCursor();
                        e.accepted = true;
                    } else if (text === "" && overview.handleKey(e)) {
                        e.accepted = true;
                    }
                }

                Text {
                    visible: searchInput.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search open windows…"
                    color: Theme.dim
                    font: searchInput.font
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: searchInput.text === ""
                ? overview.clients.length + (overview.clients.length === 1 ? " open window" : " open windows")
                    + " · " + overview.perGroup + " workspaces"
                : overview.clients.length + (overview.clients.length === 1 ? " matching window" : " matching windows")
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: Theme.fontSm
        }
    }

    Item {
        id: stage
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            topMargin: root.stageTop
            bottomMargin: root.stageBottom
        }

        Overview {
            id: overview
            anchors.centerIn: parent
            width: implicitWidth
            height: implicitHeight
            screenInfo: root.screenInfo
            live: root.shown && root.settled && !Sys.capturing
            query: searchInput.text
            onActivated: (cmd) => Sys.closeAndDispatch(cmd)
        }
    }

    Row {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: Theme.space24 }
        spacing: Theme.space24
        Text { text: "Enter  Open match"; color: Theme.faint; font.family: Theme.font; font.pixelSize: Theme.fontSm }
        Text { text: "Drag  Move window to workspace"; color: Theme.faint; font.family: Theme.font; font.pixelSize: Theme.fontSm }
        Text { text: "Esc  Close"; color: Theme.faint; font.family: Theme.font; font.pixelSize: Theme.fontSm }
    }
}
