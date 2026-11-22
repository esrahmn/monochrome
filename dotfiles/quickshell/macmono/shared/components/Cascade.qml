import QtQuick

// The contents of a panel coming in one after another, and going out in reverse order.
//
// This runs on its own clock, in milliseconds. Reveal is a stiff spring that is done in about
// 200 ms, which is too fast to stagger against: neighbours would start ~8 ms apart.
//
//   Cascade { id: stagger; open: root.shown; count: 5 }
//   opacity: stagger.fade(2)       // position 2 of 5
Item {
    id: root
    visible: false

    property bool open: false
    property int count: 4       // positions 0 .. count - 1
    property int lead: 60       // ms before the first one starts
    property int step: 75       // ms between one position and the next
    property int span: 420      // ms each one takes
    property int outMs: 300     // ms for the whole thing to go out (the panel body waits ~170 ms for it, see IslandPanelHost.closeHoldMs)

    property real t: 0
    readonly property real total: lead + Math.max(0, count - 1) * step + span

    // 0..1 for one position, no easing.
    function raw(order) {
        return Math.max(0, Math.min(1, (t - lead - order * step) / span));
    }
    // Ease out: soft start, soft landing. Gentler than a cubic, which is half done after a fifth of its time.
    function fade(order) {
        const x = 1 - raw(order);
        return 1 - x * x;
    }
    // Ease out back: lands with a small overshoot. Use it for scale, not for opacity.
    function back(order) {
        const x = raw(order) - 1;
        return 1 + 2.70158 * x * x * x + 1.70158 * x * x;
    }

    NumberAnimation { id: anim; target: root; property: "t"; easing.type: Easing.Linear }

    function play() {
        anim.stop();
        if (open) {
            anim.to = total;
            anim.duration = Math.max(1, Math.round(total - t));
        } else {
            anim.to = 0;
            anim.duration = Math.max(1, Math.round(outMs * t / total));
        }
        anim.start();
    }

    onOpenChanged: play()
    Component.onCompleted: play()
}
