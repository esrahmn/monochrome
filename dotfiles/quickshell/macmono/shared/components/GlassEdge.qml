import QtQuick
import "../../core"

Item {
    id: root

    property real radius: Theme.radiusPanel
    property real sheenHeight: height

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.transparent
        border.width: Theme.borderThin
        border.color: Theme.line
    }
}
