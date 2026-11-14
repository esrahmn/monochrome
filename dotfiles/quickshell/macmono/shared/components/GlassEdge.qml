import QtQuick
import "../../core"

// A flat hairline edge, drawn over the clipped content so it follows the rounded corners exactly.
// The old top sheen and inner rim are gone: surfaces are one flat color.
// Usage: GlassEdge { anchors.fill: parent; z: 50; radius: island.radius }
Item {
    id: root

    // Corner radius of the surface this edge sits on.
    property real radius: Theme.radiusPanel
    // Kept so old callers still compile. Not used any more.
    property real sheenHeight: height

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.transparent
        border.width: Theme.borderThin
        border.color: Theme.line
    }
}
