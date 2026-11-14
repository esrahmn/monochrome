import QtQuick
import "../../core"

// A number that chases `target` with a damped spring: the same integrator as Reveal, but for sizes
// (px) instead of 0..1 progress. Used for the island's width and height while it is already open and
// one panel morphs into another.
//   springy: false  ->  the value follows the target directly, nothing animates
// The overshoot past the target is capped in px, like Reveal's bounce.
Item {
    id: root
    visible: false

    property real target: 0
    property bool springy: true
    property real stiffness: Theme.morphStiff
    property real damping: Theme.morphDamp
    property real overshootMax: Theme.revealOvershootMax

    property real value: 0
    property real velocity: 0
    readonly property bool animating: frames.running

    // +1 while growing, -1 while shrinking: the side on which the overshoot is capped.
    property int heading: 0
    property bool ready: false

    onTargetChanged: {
        if (!ready)
            return;
        if (!springy) {
            frames.running = false;
            value = target;
            velocity = 0;
            return;
        }
        heading = target > value ? 1 : (target < value ? -1 : 0);
        frames.running = true;
    }

    Component.onCompleted: {
        value = target;
        ready = true;
    }

    FrameAnimation {
        id: frames
        onTriggered: {
            const k = root.stiffness;
            const c = 2 * root.damping * Math.sqrt(k);
            const t = root.target;

            const dt = Math.min(frames.frameTime, 0.05);
            const n = Math.max(1, Math.ceil(dt / 0.003));
            const h = dt / n;
            let x = root.value, v = root.velocity;

            for (let i = 0; i < n; i++) {
                v += (-k * (x - t) - c * v) * h;
                x += v * h;
            }

            if (root.heading > 0 && x > t + root.overshootMax) {
                x = t + root.overshootMax;
                if (v > 0) v = 0;
            } else if (root.heading < 0 && x < t - root.overshootMax) {
                x = t - root.overshootMax;
                if (v < 0) v = 0;
            }

            if (Math.abs(x - t) < 0.25 && Math.abs(v) < 4) {
                x = t;
                v = 0;
                frames.running = false;
            }

            root.value = x;
            root.velocity = v;
        }
    }
}
