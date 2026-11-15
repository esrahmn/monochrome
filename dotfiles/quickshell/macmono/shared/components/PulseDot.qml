import QtQuick
import "../../core"

Rectangle {
    id: root

    property int size: 10
    property bool pulsing: visible

    width: size
    height: size
    radius: width / 2
    color: Theme.recordRed

    SequentialAnimation on opacity {
        running: root.pulsing
        loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: Theme.durPulse * 1.4; easing.type: Theme.easeInOut }
        NumberAnimation { to: 1; duration: Theme.durPulse * 1.4; easing.type: Theme.easeInOut }
    }
}
