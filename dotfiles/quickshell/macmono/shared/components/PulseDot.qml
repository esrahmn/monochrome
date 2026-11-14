import QtQuick
import "../../core"

// The red recording dot: a circle that pulses while `pulsing` is true.
// Usage: PulseDot { size: 8 }   (set `pulsing: false` to hold it still, e.g. while hidden)
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
