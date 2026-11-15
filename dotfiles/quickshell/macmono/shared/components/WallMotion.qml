import QtQuick
import "../../core"

QtObject {
    property real t: 0
    property int dir: 1
    property real span: 1920

    readonly property real e: t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2

    readonly property real inOpacity: 1
    readonly property real inScale: 1 + (1 - e) * Theme.wallZoomIn
    readonly property real inX: dir * (1 - e) * span * Theme.wallSlide

    readonly property real outScale: 1 + e * Theme.wallZoomOut
    readonly property real outX: -dir * e * span * Theme.wallSlide * 0.3

    readonly property real dip: Theme.wallDip * e
}
