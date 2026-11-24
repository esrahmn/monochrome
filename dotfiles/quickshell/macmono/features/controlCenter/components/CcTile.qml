import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: root

    property bool active: false
    readonly property bool pressed: area.pressed
    readonly property bool hovered: hover.hovered
    signal clicked()

    radius: Theme.radiusCard
    scale: area.pressed ? Theme.pressScale : hover.hovered ? Theme.hoverScale : 1
    color: active || area.pressed ? Theme.tilePress : hover.hovered ? Theme.tileHover : Theme.tile
    Behavior on color { TweenColor { duration: Theme.durFast } }
    Behavior on scale {
        Tween {
            duration: area.pressed ? Theme.durPress : Theme.durBase
            easing.type: area.pressed ? Theme.easeOut : Theme.easeSnappy
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
