import QtQuick
import "../../core"
import "../../shared/components"

Item {
    id: root
    anchors.fill: parent
    property string panelScreen: ""

    readonly property int cheatsheetWidth: 400
    readonly property int cheatsheetPadding: 20
    readonly property int cheatsheetGroupSpacing: 22
    readonly property int cheatsheetRowHeight: 26
    readonly property var groups: KeyList.groups
    implicitWidth: cheatsheetWidth
    implicitHeight: Math.min(680, content.height + cheatsheetPadding * 2)

    Item {
        id: win
        anchors.fill: parent
        readonly property bool shown: Sys.activePanel === "cheatsheet" && Sys.activePanelScreen === root.panelScreen
        onShownChanged: if (shown) keys.forceActiveFocus()

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: (e) => { Sys.cheatOpen = false; e.accepted = true; }
        }

        Item {
            id: card
            anchors {
                top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter
                topMargin: 0; bottomMargin: 0
            }
            width: win.width
            clip: true

            Flickable {
                id: flick
                anchors { fill: parent; margins: root.cheatsheetPadding }
                contentWidth: width
                contentHeight: content.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: content
                    width: flick.width
                    spacing: root.cheatsheetGroupSpacing

                    Text {
                        text: "Keyboard shortcuts"
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.font2xl; font.weight: Theme.weightSemibold; font.letterSpacing: Theme.trackTight
                    }

                    Repeater {
                        model: groups
                        delegate: Column {
                            id: grp
                            required property var modelData
                            spacing: Theme.space8
                            width: content.width

                            Text {
                                text: grp.modelData.title.toUpperCase()
                                color: Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightSemibold
                                font.letterSpacing: Theme.trackCaps
                            }
                            Repeater {
                                model: grp.modelData.items
                                delegate: Item {
                                    id: row
                                    required property var modelData
                                    width: grp.width
                                    height: root.cheatsheetRowHeight
                                    Row {
                                        id: caps
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Theme.space4
                                        Repeater {
                                            model: row.modelData[0].split(" + ")
                                            delegate: UiKeycap {
                                                required property string modelData
                                                label: modelData
                                            }
                                        }
                                    }
                                    Text {
                                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; left: caps.right; leftMargin: Theme.space12 }
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                        text: row.modelData[1]
                                        color: Theme.dim
                                        font.family: Theme.font; font.pixelSize: Theme.fontSm
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Press any key to close"
                        color: Theme.faint
                        font.family: Theme.font; font.pixelSize: Theme.fontSm
                    }
                }
            }
        }
    }
}
