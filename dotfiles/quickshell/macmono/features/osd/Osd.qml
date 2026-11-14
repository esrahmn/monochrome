import QtQuick
import "../../core"
import "../../shared/components"

Item {
    id: root

    readonly property int osdWidth: 240
    readonly property int osdHeight: Theme.barHeight
    readonly property int osdLabelWidth: 34
    readonly property int osdTrackHeight: 6
    property string kind: "volume"

    property real level: 0

    implicitWidth: osdWidth
    implicitHeight: osdHeight

    Glyph {
        id: ic
        anchors { left: parent.left; leftMargin: Theme.space16; verticalCenter: parent.verticalCenter }
        width: Theme.iconLg
        height: Theme.iconLg
        name: root.kind === "brightness" ? "sun" : (Sys.muted ? "mute" : "volume")
        color: Theme.text
    }

    Rectangle {
        anchors { left: ic.right; leftMargin: Theme.space16; right: pct.left; rightMargin: Theme.space12; verticalCenter: parent.verticalCenter }
        height: root.osdTrackHeight
        radius: Math.min(width, height)
        color: Theme.tileHover

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.level))
            height: parent.height
            radius: Math.min(width, height)
            color: Theme.accent
            Behavior on width { Tween { duration: Theme.durFast } }
        }
    }

    Text {
        id: pct
        anchors { right: parent.right; rightMargin: Theme.space16; verticalCenter: parent.verticalCenter }
        width: root.osdLabelWidth
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.level * 100)
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.fontMd
        font.weight: Theme.weightMedium
    }
}
