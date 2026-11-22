import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../../core"
import "../../../shared/components"

ColumnLayout {
    id: root

    readonly property int mediaPosterTitleSize: 24
    readonly property int mediaPosterTitleSizeCompact: 20
    readonly property int mediaArtSizeSmall: 44
    readonly property int mediaProgressHairline: 2
    readonly property int mediaProgressRow: 10

    property var player: null
    property var players: []
    property bool panelShown: false
    property bool roomy: false
    signal playerChangeRequested(int index)

    // A Cascade from the panel. When set, the sections come in one after another and go out in
    // reverse order. Left null (MediaCard), everything is simply there.
    property var cascade: null
    function intro(order) { return cascade ? cascade.fade(order) : 1; }
    function rise(order) { return cascade ? Theme.staggerRise * (1 - cascade.fade(order)) : 0; }
    function pop(order) { return cascade ? 0.88 + 0.12 * cascade.back(order) : 1; }

    // What is on screen. It follows the player, except on a track change: the old title, artist and
    // cover fade out, the text is swapped at the bottom of the fade, and the new ones come in.
    property string shownTitle: ""
    property string shownArtist: ""
    property string shownIdentity: ""
    property string shownArt: ""
    property real swapOpacity: 1
    property real swapRise: 0
    property bool outgoing: false
    property string lastKey: ""
    readonly property string trackKey: player ? (player.trackTitle ?? "") + "\u001f" + (player.trackArtist ?? "") : ""
    readonly property string artUrl: player?.trackArtUrl ?? ""

    function syncShown() {
        shownTitle = player?.trackTitle ?? "";
        shownArtist = player?.trackArtist ?? "";
        shownIdentity = player?.identity ?? "";
        shownArt = artUrl;
    }

    onTrackKeyChanged: {
        const first = lastKey === "";
        lastKey = trackKey;
        if (first || !visible || trackKey === "") {
            swapAnim.stop();
            outgoing = false;
            swapOpacity = 1;
            swapRise = 0;
            syncShown();
        } else {
            swapAnim.restart();
        }
    }
    // Spotify sends the cover a moment after the title. Wait a little so it joins the swap if it can.
    onArtUrlChanged: artTimer.restart()
    Timer {
        id: artTimer
        interval: 90
        onTriggered: if (!root.outgoing) root.shownArt = root.artUrl
    }
    Component.onCompleted: {
        lastKey = trackKey;
        syncShown();
    }

    SequentialAnimation {
        id: swapAnim
        ScriptAction { script: root.outgoing = true }
        ParallelAnimation {
            NumberAnimation { target: root; property: "swapOpacity"; to: 0; duration: 170; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "swapRise"; to: -6; duration: 170; easing.type: Easing.OutQuad }
        }
        ScriptAction {
            script: {
                root.syncShown();
                root.outgoing = false;
                root.swapRise = 8;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "swapOpacity"; to: 1; duration: 400; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "swapRise"; to: 0; duration: 400; easing.type: Easing.OutQuad }
        }
    }

    readonly property int artRadius: roomy ? Theme.radiusCard : Theme.radiusCard
    readonly property int artGlyph: roomy ? 24 : 22
    readonly property int switchSize: roomy ? 28 : 26
    readonly property int bigButton: roomy ? 48 : 44
    readonly property int smallButton: roomy ? 40 : 38
    readonly property int bigGlyph: roomy ? 19 : 18
    readonly property int buttonGap: roomy ? 8 : 6

    readonly property real len: player?.length ?? 0
    property real pos: 0

    spacing: roomy ? Theme.space12 : Theme.space12

    MediaClock {
        id: clock
        player: root.player
        active: root.panelShown
        onPolled: root.pos = clock.sample()
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.panelShown && root.player !== null && root.player.isPlaying
        onTriggered: {
            root.player.positionChanged();
            root.pos = clock.sample();
        }
    }

    onPanelShownChanged: {
        if (panelShown && player)
            pos = clock.sample();
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: root.roomy ? Theme.space16 : Theme.space12
        layoutDirection: Qt.RightToLeft

        Rectangle {
            Layout.preferredWidth: root.mediaArtSizeSmall
            Layout.preferredHeight: root.mediaArtSizeSmall
            Layout.alignment: Qt.AlignTop
            radius: root.artRadius
            color: Theme.tile
            clip: true
            opacity: root.intro(0) * root.swapOpacity
            scale: root.pop(0) * (0.94 + 0.06 * root.swapOpacity)
            Glyph {
                visible: art.status !== Image.Ready
                anchors.centerIn: parent
                width: root.artGlyph; height: root.artGlyph
                name: "play"
                color: Theme.dim
            }
            Image {
                id: art
                anchors.fill: parent
                source: root.shownArt
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 144
                sourceSize.height: 144
                visible: false
            }
            Rectangle { id: artMask; anchors.fill: parent; radius: root.artRadius; visible: false; layer.enabled: true }
            MultiEffect {
                opacity: art.status === Image.Ready ? 1 : 0
                visible: opacity > 0.001
                Behavior on opacity { Tween { duration: 260 } }
                anchors.fill: parent
                source: art
                saturation: -1.0
                maskEnabled: true
                maskSource: artMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space2
            opacity: root.intro(1) * root.swapOpacity
            transform: Translate { y: root.rise(1) + root.swapRise }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
                lineHeight: 0.95
                text: root.shownTitle || "Unknown title"
                color: Theme.text
                font.family: Theme.font; font.weight: Theme.weightSemibold
                font.pixelSize: root.roomy ? root.mediaPosterTitleSize : root.mediaPosterTitleSizeCompact
                font.letterSpacing: Theme.trackTight
            }
            Text {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space8
                elide: Text.ElideRight
                text: (root.shownArtist + ((root.shownArtist && root.shownIdentity) ? "  ·  " : "") + root.shownIdentity).toUpperCase()
                color: Theme.dim
                font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
                font.letterSpacing: Theme.trackCaps
            }
        }

        MouseArea {
            id: switchArea
            visible: root.players.length > 1
            Layout.preferredWidth: root.switchSize
            Layout.preferredHeight: root.switchSize
            Layout.alignment: Qt.AlignTop
            hoverEnabled: true
            opacity: root.intro(1)
            onClicked: root.playerChangeRequested((root.players.indexOf(root.player) + 1) % root.players.length)
            Rectangle { anchors.fill: parent; radius: Theme.radiusControl; color: switchArea.containsMouse ? Theme.tileHover : Theme.transparent }
            Glyph { anchors.centerIn: parent; width: Theme.iconSm; height: Theme.iconSm; name: "chevron"; rotation: -90; color: Theme.dim }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.len > 0
        spacing: Theme.space4
        opacity: root.intro(2)
        transform: Translate { y: root.rise(2) }
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.mediaProgressRow
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: root.mediaProgressHairline; radius: Math.min(width, height) / 2
                color: Theme.tileHover
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.pos / Math.max(1, root.len)))
                    height: parent.height; radius: Math.min(width, height) / 2
                    color: Theme.accent
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: (mouse) => {
                    const target = root.len * Math.max(0, Math.min(1, mouse.x / width));
                    clock.seekTo(target);
                    root.pos = target;
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: Sys.formatMediaTime(root.pos); color: Theme.dim; font.family: Theme.font; font.pixelSize: Theme.fontXs }
            Item { Layout.fillWidth: true }
            Text { text: "-" + Sys.formatMediaTime(root.len - root.pos); color: Theme.dim; font.family: Theme.font; font.pixelSize: Theme.fontXs }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0
        opacity: root.intro(3)
        transform: Translate { y: root.rise(3) }
        Item { Layout.fillWidth: true }
        Repeater {
            model: ["prev", "toggle", "next"]
            delegate: MouseArea {
                id: control
                required property string modelData
                readonly property bool big: modelData === "toggle"
                Layout.preferredWidth: big ? root.bigButton : root.smallButton
                Layout.preferredHeight: big ? root.bigButton : root.smallButton
                Layout.leftMargin: root.buttonGap; Layout.rightMargin: root.buttonGap
                hoverEnabled: true
                enabled: modelData === "prev" ? (root.player?.canGoPrevious ?? false)
                       : modelData === "next" ? (root.player?.canGoNext ?? false)
                       : (root.player?.canTogglePlaying ?? false)
                opacity: enabled ? 1 : Theme.opacityDisabled
                onClicked: {
                    if (modelData === "prev") root.player.previous();
                    else if (modelData === "next") root.player.next();
                    else root.player.togglePlaying();
                }
                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(width, height) / 2
                    color: control.containsMouse ? Theme.tileHover : (control.big ? Theme.tile : Theme.transparent)
                    border.width: control.big ? Theme.borderThin : 0
                    border.color: Theme.line
                }
                Glyph {
                    anchors.centerIn: parent
                    width: control.big ? root.bigGlyph : 17; height: width
                    name: control.modelData === "toggle" ? (root.player?.isPlaying ? "pause" : "play") : control.modelData
                    color: Theme.text
                }
            }
        }
        Item { Layout.fillWidth: true }
    }
}
