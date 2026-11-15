import QtQuick
import "../../core"

Row {
    id: root

    property int boltSize: Theme.iconSm

    visible: Sys.batAvailable
    spacing: Theme.space8

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(Sys.batPercent * 100) + "%"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontMd
    }
    BatteryIcon {
        anchors.verticalCenter: parent.verticalCenter
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
