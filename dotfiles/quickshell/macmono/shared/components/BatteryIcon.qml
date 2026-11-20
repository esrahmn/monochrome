import QtQuick
import "../../core"

Item {
    id: root

    property bool showPercent: false

    readonly property int bodyWidth: showPercent ? 34 : 24
    readonly property int bodyHeight: showPercent ? 16 : 12
    readonly property int nubHeight: showPercent ? 6 : 4
    readonly property string label: Math.round(Sys.batPercent * 100)

    implicitWidth: bodyWidth + 3
    implicitHeight: bodyHeight

    Rectangle {
        id: body
        width: root.bodyWidth; height: root.bodyHeight
        radius: height * 0.3
        color: Theme.transparent
        border.width: Theme.borderThin; border.color: Theme.dim

        Text {
            id: lightLabel
            visible: root.showPercent
            x: (body.width - width) / 2
            y: (body.height - height) / 2
            text: root.label
            color: Theme.text
            font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
        }

        Rectangle {
            id: fill
            x: 2; y: 2; height: parent.height - 4
            width: Math.max(2, (parent.width - 4) * Math.min(1, Sys.batPercent))
            radius: parent.radius * 0.45
            color: Sys.batCharging ? Theme.accent : Theme.text
            clip: root.showPercent

            Text {
                visible: root.showPercent
                x: lightLabel.x - fill.x
                y: lightLabel.y - fill.y
                text: root.label
                color: Theme.textOnAccent
                font: lightLabel.font
            }
        }
    }

    Rectangle {
        x: root.bodyWidth + 1; y: (root.bodyHeight - root.nubHeight) / 2
        width: 2; height: root.nubHeight
        radius: Math.min(width, height) / 2
        color: Theme.dim
    }
}
