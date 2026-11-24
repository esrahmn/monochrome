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

    // Rows come in one after another when the sheet opens, and go out in reverse order when it closes.
    Cascade { id: stagger; open: win.shown; count: root.groups.length + 2; step: 55 }
    function intro(order) { return stagger.fade(order); }
    function rise(order) { return Theme.staggerRise * (1 - stagger.fade(order)); }

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
                        opacity: root.intro(0)
                        scale: 0.98 + 0.02 * stagger.back(0)
                        transform: Translate { y: root.rise(0) }
                        text: "Keyboard shortcuts"
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.font2xl; font.weight: Theme.weightSemibold; font.letterSpacing: Theme.trackTight
                    }

                    Repeater {
                        model: groups
                        delegate: Column {
                            id: grp
                            required property var modelData
                            required property int index
                            spacing: Theme.space8
                            width: content.width
                            opacity: root.intro(index + 1)
                            transform: Translate { y: root.rise(index + 1) }

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
                        opacity: root.intro(root.groups.length + 1)
                        transform: Translate { y: root.rise(root.groups.length + 1) }
                        text: "Press any key to close"
                        color: Theme.faint
                        font.family: Theme.font; font.pixelSize: Theme.fontSm
                    }
                }
            }
        }
    }
}
