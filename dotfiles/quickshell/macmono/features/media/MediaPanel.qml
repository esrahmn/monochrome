import "../../core"
import "../../shared/components"
import QtQuick
import Quickshell.Services.Mpris
import "components"

Item {
    id: root

    property string panelScreen: ""
    readonly property bool shown: Sys.activePanel === "media" && Sys.activePanelScreen === panelScreen
    readonly property int mediaPopupLyricsHeight: 210
    property int playerIndex: -1
    readonly property var p: Sys.mediaPlayer(Mpris.players.values, playerIndex)

    implicitWidth: Sys.mediaPopupWidth
    implicitHeight: p ? content.implicitHeight + lyrics.height + Theme.space16 * 3 : empty.implicitHeight + Theme.space16 * 2
    width: parent ? parent.width : implicitWidth
    height: parent ? parent.height : implicitHeight
    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Escape) {
            Sys.mediaOpen = false;
            e.accepted = true;
        } else if (!root.p) {
            return ;
        } else if (e.key === Qt.Key_Space) {
            root.p.togglePlaying();
            e.accepted = true;
        } else if (e.key === Qt.Key_Left) {
            root.p.previous();
            e.accepted = true;
        } else if (e.key === Qt.Key_Right) {
            root.p.next();
            e.accepted = true;
        }
    }

    Item {
        id: card

        width: root.width
        height: root.parent ? Math.min(root.implicitHeight, root.height) : root.implicitHeight

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }

        CavaWave {
            height: Math.min(card.height * 0.4, 150)
            visible: root.p !== null && Settings.visualizerEnabled && Settings.visualizerInPopup
            levels: Sys.mediaVisualizerLevels
            cornerRadius: Theme.radiusPanel - Theme.borderThin

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Theme.borderThin
            }

        }

        Text {
            id: empty

            visible: !root.p
            anchors.centerIn: parent
            text: "Nothing is playing"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.fontMd
        }

        MediaPlayerView {
            id: content

            visible: root.p !== null
            roomy: true
            player: root.p
            players: Mpris.players.values
            panelShown: root.shown
            onPlayerChangeRequested: (index) => {
                return root.playerIndex = index;
            }

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.space16
            }

        }

        LyricsView {
            id: lyrics

            height: root.mediaPopupLyricsHeight
            player: root.p
            active: root.shown
            visible: root.p !== null

            anchors {
                left: parent.left
                right: parent.right
                top: content.bottom
                leftMargin: Theme.space16
                rightMargin: Theme.space16
                topMargin: Theme.space16
            }

        }

    }

}
