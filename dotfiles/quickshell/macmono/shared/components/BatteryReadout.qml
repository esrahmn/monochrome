import QtQuick
import "../../core"

// Battery as the island draws it: percentage, battery icon, and a bolt while charging.
// Hides itself on machines without a battery.
Row {
    id: root

    // The bolt is a little smaller in the island than on the lock screen, so it can be set.
    property int boltSize: Theme.iconSm
    // true: the percentage sits inside the battery icon instead of beside it.
    property bool inside: false

    visible: Sys.batAvailable
    spacing: Theme.space8

    Text {
        visible: !root.inside
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(Sys.batPercent * 100) + "%"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontMd
    }
    BatteryIcon {
        anchors.verticalCenter: parent.verticalCenter
        showPercent: root.inside
    }
    Glyph {
        visible: Sys.batCharging
        anchors.verticalCenter: parent.verticalCenter
        width: root.boltSize
        height: root.boltSize
        name: "bolt"
        color: Theme.text
    }
}
