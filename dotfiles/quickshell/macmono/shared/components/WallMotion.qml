import QtQuick
import "../../core"

// One motion formula for wallpaper changes (used by WallLayer, Wallpaper and the picker preview).
// The new image slides in over the old one (from the right going forward, from the left going back),
// while the old one drifts the other way more slowly and darkens: a slide, not a fade.
// t: linear 0..1 progress of the change. The incoming layer uses in*, the outgoing layer uses out*.
QtObject {
    property real t: 0
    property int dir: 1        // +1 = forward (enters from the right), -1 = backward
    property real span: 1920   // surface width, used for the slide distance

    // In-out cubic: the slide starts and ends gently.
    readonly property real e: t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2

    readonly property real inOpacity: 1
    readonly property real inScale: 1 + (1 - e) * Theme.wallZoomIn
    readonly property real inX: dir * (1 - e) * span * Theme.wallSlide

    readonly property real outScale: 1 + e * Theme.wallZoomOut
    readonly property real outX: -dir * e * span * Theme.wallSlide * 0.3

    // How dark the outgoing image is (0 at the start, Theme.wallDip when it is fully covered)
    readonly property real dip: Theme.wallDip * e
}
