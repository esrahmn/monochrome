import QtQuick

// Follows a media player, except on a track change: the old title, artist and cover fade out, the
// text is swapped at the bottom of the fade, and the new ones come in.
//
//   TrackSwap { id: swap; player: root.player; active: root.visible }
//   Text { text: swap.shownTitle; opacity: swap.fade; transform: Translate { y: swap.rise } }
//
// Spotify sends the cover a moment after the title, so a new cover waits 90 ms to join the swap.
Item {
    id: root
    visible: false

    property var player: null
    property bool active: true      // false: just follow the player, without animating

    // What to show. Read these instead of the player.
    property string shownTitle: ""
    property string shownArtist: ""
    property string shownIdentity: ""
    property string shownArt: ""

    // Multiply fade into the opacity, and add rise to the y offset, of whatever shows them.
    property real fade: 1
    property real rise: 0

    property bool outgoing: false
    property string lastKey: ""
    readonly property string trackKey: player ? (player.trackTitle ?? "") + "\u001f" + (player.trackArtist ?? "") : ""
    readonly property string artUrl: player?.trackArtUrl ?? ""

    function sync() {
        shownTitle = player?.trackTitle ?? "";
        shownArtist = player?.trackArtist ?? "";
        shownIdentity = player?.identity ?? "";
        shownArt = artUrl;
    }

    onTrackKeyChanged: {
        const first = lastKey === "";
        lastKey = trackKey;
        if (first || !active || trackKey === "") {
            anim.stop();
            outgoing = false;
            fade = 1;
            rise = 0;
            sync();
        } else {
            anim.restart();
        }
    }
    onArtUrlChanged: artTimer.restart()
    Timer {
        id: artTimer
        interval: 90
        onTriggered: if (!root.outgoing) root.shownArt = root.artUrl
    }
    Component.onCompleted: {
        lastKey = trackKey;
        sync();
    }

    SequentialAnimation {
        id: anim
        ScriptAction { script: root.outgoing = true }
        ParallelAnimation {
            NumberAnimation { target: root; property: "fade"; to: 0; duration: 170; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "rise"; to: -6; duration: 170; easing.type: Easing.OutQuad }
        }
        ScriptAction {
            script: {
                root.sync();
                root.outgoing = false;
                root.rise = 8;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "fade"; to: 1; duration: 400; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "rise"; to: 0; duration: 400; easing.type: Easing.OutQuad }
        }
    }
}
