import QtQuick
import "../../core"

Item {
    id: root

    property var cells: []
    property var selectedDate: new Date()
    property real cellWidth: 0
    property int dayHeight: 0
    property int circleSize: 0
    property bool live: true
    signal picked(var date)

    implicitHeight: Math.ceil(cells.length / 7) * dayHeight

    Grid {
        width: parent.width
        columns: 7

        Repeater {
            model: root.cells

            delegate: Item {
                id: dayCell

                required property var modelData
                readonly property bool isSelected: modelData.date.getFullYear() === root.selectedDate.getFullYear()
                    && modelData.date.getMonth() === root.selectedDate.getMonth()
                    && modelData.date.getDate() === root.selectedDate.getDate()

                width: root.cellWidth
                height: root.dayHeight

                Rectangle {
                    visible: modelData.today && !isSelected
                    anchors.centerIn: parent
                    width: root.circleSize + 6
                    height: width
                    radius: width / 2
                    color: Theme.transparent
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent, 0.6)
                    SequentialAnimation on opacity {
                        running: dayCell.visible && root.live
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.3; duration: 1100; easing.type: Theme.easeInOut }
                        NumberAnimation { from: 0.3; to: 1; duration: 1100; easing.type: Theme.easeInOut }
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: root.circleSize
                    height: root.circleSize
                    radius: Math.min(width, height) / 2
                    color: dayArea.containsMouse && !isSelected ? Theme.tileHover : (isSelected ? Theme.accent : Theme.transparent)
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData.day
                    color: isSelected ? Theme.textOnAccent : (modelData.inMonth ? Theme.text : Theme.faint)
                    font.family: Theme.font
                    font.pixelSize: Theme.fontLg
                    font.weight: isSelected || modelData.today ? Theme.weightSemibold : Theme.weightRegular
                }

                MouseArea {
                    id: dayArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(dayCell.modelData.date)
                }
            }
        }
    }
}
