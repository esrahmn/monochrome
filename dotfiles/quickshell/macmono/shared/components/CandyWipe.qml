import QtQuick

// White-on-transparent capsule used as the mask source for the wallpaper
// wipe. Size it to the surface it masks; MultiEffect stretches it anyway.
Item {
    id: root

    property real t: 0
    property int dir: 1
    property real span: 1920
    property real vspan: 1080

    readonly property real e: t <= 0 ? 0 : (t >= 1 ? 1 : (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2))

    // The pill starts just off the edge the new wallpaper comes from, then
    // grows and lands centered - by then it is wider than the surface, so the
    // whole frame is revealed.
    readonly property real entryWidth: span * 0.4
    readonly property real pillWidth: span * (0.4 + 0.8 * e)
    readonly property real pillHeight: vspan * (0.3 + 0.55 * e)
    readonly property real entryX: dir > 0 ? span + entryWidth / 2 : -entryWidth / 2
    readonly property real centerX: entryX + (span / 2 - entryX) * e
    readonly property real radius: Math.min(pillWidth, pillHeight) / 2 * (1 - smooth(0.78, 1, e))

    // Last stretch: a full-frame shape fades in so the corners are covered
    // while the capsule is still rounding off.
    readonly property real cover: smooth(0.8, 1, e)

    function smooth(a, b, x) {
        if (x <= a) return 0;
        if (x >= b) return 1;
        const u = (x - a) / (b - a);
        return u * u * (3 - 2 * u);
    }

    Rectangle {
        color: "white"
        x: root.centerX - root.pillWidth / 2
        y: root.vspan / 2 - root.pillHeight / 2
        width: root.pillWidth
        height: root.pillHeight
        radius: root.radius
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: root.cover
    }
}
