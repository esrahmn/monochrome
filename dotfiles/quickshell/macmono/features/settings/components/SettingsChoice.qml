import QtQuick
import "../../../core"
import "../../../shared/components"

Rectangle {
    id: chip
    property string label
    property bool on: false
    signal picked()
    implicitWidth: chipText.implicitWidth + SettingsMetrics.settingsButtonPadX * 2
    height: SettingsMetrics.settingsChipHeight
    radius: Theme.radiusCard
    color: on ? Theme.tileHover : (chipArea.containsMouse ? Theme.tile : Theme.tile)
    border.width: Theme.borderThin
    border.color: on ? Theme.line : Theme.line
    scale: chipArea.pressed ? Theme.pressScale : chipArea.containsMouse ? 1.02 : 1
    Behavior on color { TweenColor { duration: Theme.durFast } }
    Behavior on scale {
        Tween {
            duration: chipArea.pressed ? Theme.durPress : Theme.durBase
            easing.type: chipArea.pressed ? Theme.easeOut : Theme.easeSnappy
        }
    }
    SettingsText {
        id: chipText
        anchors.centerIn: parent
        text: chip.label
        color: chip.on ? Theme.text : Theme.text
        font.pixelSize: Theme.fontSm
        font.weight: chip.on ? Theme.weightSemibold : Theme.weightRegular
    }
    MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.picked() }
}
