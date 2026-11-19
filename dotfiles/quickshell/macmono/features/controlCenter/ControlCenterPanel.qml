import "../../core"
import "../../shared/components"
import "../notifications"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "components"

Item {
    id: root

    property string panelScreen: ""
    readonly property bool shown: Sys.activePanel === "controlCenter" && Sys.activePanelScreen === panelScreen
    readonly property int ccWidth: 500
    readonly property int ccPadding: 24
    readonly property int ccAvatarSize: 48
    readonly property int ccHeaderButtonSize: 40
    property string expanded: ""
    property int playerIndex: -1
    readonly property var player: Sys.mediaPlayer(Mpris.players.values, playerIndex)
    readonly property bool typing: wifiOrbit.typing
    readonly property bool holdOpen: typing || Sys.wifiConnecting !== ""

    function toggleExpand(name) {
        expanded = expanded === name ? "" : name;
        if (expanded === "wifi")
            Sys.scanWifi();

    }

    implicitWidth: ccWidth
    implicitHeight: col.implicitHeight + 2 * ccPadding
    width: parent ? parent.width : implicitWidth
    height: parent ? parent.height : implicitHeight
    onShownChanged: {
        if (shown)
            flick.contentY = 0;
        else
            expanded = "";
    }

    Item {
        id: body

        width: root.width
        height: card.height

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }

        Item {
            id: card

            height: root.parent ? Math.min(col.implicitHeight + 2 * root.ccPadding, root.height) : col.implicitHeight + 2 * root.ccPadding

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

        }

        Flickable {
            id: flick

            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            anchors {
                top: card.top
                left: card.left
                right: card.right
                bottom: card.bottom
                margins: root.ccPadding
            }

            ColumnLayout {
                id: col

                width: flick.width
                spacing: Theme.space16

                RowLayout {
                    visible: root.expanded !== "wifi"
                    Layout.fillWidth: true
                    spacing: Theme.space12

                    Rectangle {
                        implicitWidth: root.ccAvatarSize
                        implicitHeight: root.ccAvatarSize
                        radius: Math.min(width, height) / 2
                        color: Theme.tileHover

                        // Round avatar without a color effect: ClippingRectangle clips the corners directly,
                        // with no separate layer mask + shader effect (two offscreen renders).
                        ClippingRectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.transparent
                            visible: avatarImg.status === Image.Ready

                            Image {
                                id: avatarImg

                                anchors.fill: parent
                                source: Sys.avatar !== "" ? "file://" + Sys.avatar : ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 72
                                sourceSize.height: 72
                                asynchronous: true
                            }

                        }

                        Text {
                            visible: avatarImg.status !== Image.Ready
                            anchors.centerIn: parent
                            text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontLg
                            font.weight: Theme.weightSemibold
                        }

                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: Quickshell.env("USER") || "user"
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontXl
                            font.weight: Theme.weightSemibold
                            font.letterSpacing: Theme.trackSnug
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: Qt.formatDate(Sys.now, "dddd, d MMMM")
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSm
                        }

                    }

                    CcTile {
                        Layout.preferredWidth: root.ccHeaderButtonSize
                        Layout.preferredHeight: root.ccHeaderButtonSize
                        radius: height / 2
                        active: Sys.recActive || Sys.recStartPending
                        onClicked: {
                            if (Sys.recActive)
                                Sys.recordStop();
                            else if (!Sys.recStartPending)
                                Sys.recordStart("full", "none");
                        }

                        Glyph {
                            anchors.centerIn: parent
                            width: Theme.iconLg
                            height: Theme.iconLg
                            name: Sys.recActive ? "stop" : "record"
                            color: Theme.text
                        }

                    }

                }

                ColumnLayout {
                    visible: root.expanded !== "wifi"
                    Layout.fillWidth: true
                    spacing: Theme.space8

                    CcNetworkTiles {
                        expanded: root.expanded
                        onRequestExpand: (key) => {
                            return root.toggleExpand(key);
                        }
                    }

                    CcQuickToggles {
                    }

                }

                // Wi-Fi page: a back row on top, the list below. The rest of the panel is hidden meanwhile.
                MouseArea {
                    id: wifiBack
                    visible: root.expanded === "wifi"
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.ccHeaderButtonSize
                    hoverEnabled: true
                    onClicked: root.expanded = ""

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusControl
                        color: wifiBack.containsMouse ? Theme.tile : Theme.transparent
                        Behavior on color { TweenColor { duration: Theme.durFast } }
                    }
                    Row {
                        anchors { left: parent.left; leftMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                        spacing: Theme.space8
                        Glyph {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.iconSm; height: Theme.iconSm
                            name: "chevron"
                            rotation: 90
                            color: Theme.text
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Wi-Fi"
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontLg; font.weight: Theme.weightSemibold
                        }
                    }
                }

                WifiOrbit {
                    id: wifiOrbit
                    visible: root.expanded === "wifi"
                    Layout.fillWidth: true
                }

                BtList {
                    open: root.expanded === "bt"
                    Layout.fillWidth: true
                }

                CcSliders {
                    visible: root.expanded !== "wifi"
                    expanded: root.expanded
                    onRequestExpand: (key) => {
                        return root.toggleExpand(key);
                    }
                }

                CcMedia {
                    // CcMedia hides itself without a player; keep that and add the page rule.
                    visible: root.expanded !== "wifi" && root.player !== null
                    player: root.player
                    players: Mpris.players.values
                    panelShown: root.shown
                    onPlayerChangeRequested: (index) => {
                        return root.playerIndex = index;
                    }
                }

                NotificationHistory {
                    // NotificationHistory hides itself when empty; keep that and add the page rule.
                    visible: root.expanded !== "wifi" && Sys.notifHistory.length > 0
                    Layout.fillWidth: true
                }

            }

        }

    }

}
