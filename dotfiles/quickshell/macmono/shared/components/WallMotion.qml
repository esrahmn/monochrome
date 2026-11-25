import QtQuick
import "../../core"

QtObject {
    property real t: 0
    property int dir: 1
    property real span: 1920
    property real vspan: 1080

    readonly property real e: t <= 0 ? 0 : (t >= 1 ? 1 : (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2))

    // The incoming image is revealed by the capsule mask, so it stays put;
    // only the outgoing one drifts back a little for depth.
    readonly property real inOpacity: 1
    readonly property real inScale: 1
    readonly property real inX: 0

    readonly property real outScale: 1 + e * Theme.wallZoomOut
    readonly property real outX: 0
}
