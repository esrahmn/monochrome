import "../../core"
import "../../shared/components"
import QtQuick

Item {
    id: root

    property string panelScreen: ""
    property int selectedIndex: 2
    readonly property bool panelActive: Sys.activePanel === "power" && Sys.activePanelScreen === panelScreen
    readonly property var actions: [{
        "act": "lock",
        "label": "Lock",
        "glyph": "lock",
        "key": "L"
    }, {
        "act": "sleep",
        "label": "Sleep",
        "glyph": "sleep",
        "key": "S"
    }, {
        "act": "logout",
        "label": "Log out",
        "glyph": "logout",
        "key": "O"
    }, {
        "act": "restart",
        "label": "Restart",
        "glyph": "restart",
        "key": "R"
    }, {
        "act": "shutdown",
        "label": "Shut down",
        "glyph": "power",
        "key": "P"
    }]

    // Buttons come in one after another when the panel opens, and go out in reverse order when it closes.
    Cascade { id: stagger; open: root.panelActive; count: root.actions.length; step: 45 }
    function intro(order) { return stagger.fade(order); }
    function rise(order) { return Theme.staggerRise * (1 - stagger.fade(order)); }

    function run(action) {
        Sys.powerOpen = false;
        Sys.power(action);
    }

    implicitWidth: actionRow.implicitWidth + Theme.space24
    implicitHeight: actionRow.implicitHeight + Theme.space24
    onPanelActiveChanged: {
        if (panelActive)
            selectedIndex = 2;

    }
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            Sys.powerOpen = false;
            event.accepted = true;
            return ;
        }
        if (event.key === Qt.Key_Left) {
            selectedIndex = (selectedIndex + actions.length - 1) % actions.length;
            event.accepted = true;
            return ;
        }
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            selectedIndex = (selectedIndex + 1) % actions.length;
            event.accepted = true;
            return ;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            run(actions[selectedIndex].act);
            event.accepted = true;
            return ;
        }
        const keyText = (event.text || "").toUpperCase();
        for (const action of actions) {
            if (action.key === keyText) {
                run(action.act);
                event.accepted = true;
                return ;
            }
        }
    }

    Row {
        id: actionRow

        anchors.centerIn: parent
        spacing: Theme.space4

        Repeater {
            model: root.actions

            delegate: Column {
                id: actionCard

                required property var modelData
                required property int index
                readonly property bool active: root.selectedIndex === index
                readonly property bool hovered: hitArea.containsMouse

                width: 66
                spacing: Theme.space4
                opacity: root.intro(index)
                scale: 0.94 + 0.06 * stagger.back(index)
                transform: Translate { y: root.rise(index) }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 44
                    height: 44
                    radius: height / 2
                    color: actionCard.active || actionCard.hovered ? Theme.tileHover : Theme.tile
                    border.width: Theme.borderThin
                    border.color: actionCard.active ? Theme.text : Theme.line
                    scale: hitArea.pressed ? 0.9 : actionCard.hovered ? 1.07 : 1
                    Behavior on scale {
                        Tween {
                            duration: hitArea.pressed ? Theme.durPress : Theme.durBase
                            easing.type: hitArea.pressed ? Theme.easeOut : Theme.easeSnappy
                        }
                    }

                    Glyph {
                        anchors.centerIn: parent
                        width: Theme.iconLg
                        height: Theme.iconLg
                        name: actionCard.modelData.glyph
                        color: Theme.text
                    }

                    MouseArea {
                        id: hitArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = actionCard.index
                        onClicked: root.run(actionCard.modelData.act)
                    }

                    Behavior on color {
                        TweenColor {
                            duration: Theme.durFast
                        }

                    }

                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    text: actionCard.modelData.label
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: actionCard.active ? Theme.text : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontXs
                    font.weight: Theme.weightMedium
                }

            }

        }

    }

}
