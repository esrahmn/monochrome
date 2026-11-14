import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../core"

Item {
    id: root

    property string panelScreen: ""
    property var stack: []

    readonly property int trayBackHeight: 30
    readonly property int trayCheckWidth: 14
    readonly property bool panelActive: Sys.activePanel === "tray" && Sys.activePanelScreen === panelScreen
    readonly property var currentHandle: stack.length > 0
        ? stack[stack.length - 1]
        : (Sys.trayMenuItem ? Sys.trayMenuItem.menu : null)

    implicitWidth: Math.max(190, Math.min(420, menuList.implicitWidth + Theme.space16))
    implicitHeight: menuList.implicitHeight + Theme.space16

    onPanelActiveChanged: {
        if (panelActive) stack = [];
    }

    function close() {
        Sys.trayMenuOpen = false;
    }

    Keys.onEscapePressed: close()

    QsMenuOpener {
        id: opener
        menu: root.currentHandle
    }

    Item {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            id: menuList
            anchors.fill: parent
            anchors.margins: Theme.space8
            spacing: Theme.space2

            Rectangle {
                visible: root.stack.length > 0
                Layout.fillWidth: true
                implicitHeight: root.trayBackHeight
                radius: Theme.radiusControl
                color: backArea.containsMouse ? Theme.tileHover : Theme.transparent

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.space12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "‹  Back"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontMd
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.stack = root.stack.slice(0, -1)
                }
            }

            Repeater {
                model: opener.children || []

                delegate: Item {
                    id: menuRow
                    required property var modelData

                    readonly property bool separator: modelData.isSeparator
                    Layout.fillWidth: true
                    implicitHeight: separator ? 9 : 30
                    implicitWidth: separator ? 0 : (label.implicitWidth + 64)

                    Rectangle {
                        visible: menuRow.separator
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: Theme.space8
                            rightMargin: Theme.space8
                        }
                        height: Theme.borderThin
                        color: Theme.tile
                    }

                    Rectangle {
                        visible: !menuRow.separator
                        anchors.fill: parent
                        radius: Theme.radiusControl
                        color: (entryArea.containsMouse && menuRow.modelData.enabled)
                            ? Theme.tileHover : Theme.transparent

                        Text {
                            id: checkMark
                            anchors {
                                left: parent.left
                                leftMargin: Theme.space12
                                verticalCenter: parent.verticalCenter
                            }
                            width: root.trayCheckWidth
                            text: menuRow.modelData.buttonType === QsMenuButtonType.None ? ""
                                : (menuRow.modelData.checkState === Qt.Checked
                                    ? (menuRow.modelData.buttonType === QsMenuButtonType.RadioButton ? "●" : "✓")
                                    : "")
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSm
                        }

                        IconImage {
                            id: icon
                            visible: menuRow.modelData.icon !== ""
                            anchors {
                                left: checkMark.right
                                leftMargin: Theme.space4
                                verticalCenter: parent.verticalCenter
                            }
                            width: Theme.iconMd
                            height: Theme.iconMd
                            source: menuRow.modelData.icon
                        }

                        Text {
                            id: label
                            anchors {
                                left: icon.visible ? icon.right : checkMark.right
                                leftMargin: Theme.space8
                                right: parent.right
                                rightMargin: Theme.space32
                                verticalCenter: parent.verticalCenter
                            }
                            text: menuRow.modelData.text
                            elide: Text.ElideRight
                            color: menuRow.modelData.enabled ? Theme.text : Theme.faint
                            font.family: Theme.font
                            font.pixelSize: Theme.fontMd
                        }

                        Text {
                            visible: menuRow.modelData.hasChildren
                            anchors {
                                right: parent.right
                                rightMargin: Theme.space12
                                verticalCenter: parent.verticalCenter
                            }
                            text: "›"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontLg
                        }

                        MouseArea {
                            id: entryArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (!menuRow.modelData.enabled) return;
                                if (menuRow.modelData.hasChildren) {
                                    root.stack = root.stack.concat([menuRow.modelData]);
                                    return;
                                }
                                menuRow.modelData.triggered();
                                root.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
