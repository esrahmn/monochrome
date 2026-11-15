import QtQuick
import "../../core"
import "."

// Esc clears the text first, then emits escaped; navigation keys go to the owner.
FocusScope {
    id: root

    readonly property int searchHeight: 40

    property alias text: input.text
    property alias field: input
    property string placeholder: ""
    property bool boxed: true
    property real radius: Theme.radiusCard
    property real padX: Theme.space16
    property bool escapeAccepted: true

    signal accepted()
    signal escaped()
    signal keyPressed(var event)

    function clear() { input.text = ""; }
    function focusField() { input.forceActiveFocus(); }

    implicitHeight: root.searchHeight

    Rectangle {
        anchors.fill: parent
        visible: root.boxed
        radius: root.radius
        color: Theme.tile
        border.width: input.activeFocus ? Theme.borderThin : 0
        border.color: Theme.lineFocus
    }

    Glyph {
        id: glyph
        anchors { left: parent.left; leftMargin: root.padX; verticalCenter: parent.verticalCenter }
        width: Theme.iconMd; height: Theme.iconMd
        name: "search"
        color: input.text !== "" ? Theme.text : Theme.dim
    }

    TextInput {
        id: input
        anchors {
            left: glyph.right; leftMargin: Theme.space8
            right: parent.right; rightMargin: root.padX
            verticalCenter: parent.verticalCenter
        }
        focus: true
        clip: true
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.textOnAccent
        font.family: Theme.font
        font.pixelSize: Theme.fontMd
        onAccepted: root.accepted()

        Keys.onPressed: (event) => {
            root.keyPressed(event);
            if (event.accepted || event.key !== Qt.Key_Escape) return;
            if (input.text !== "") {
                input.text = "";
                event.accepted = true;
            } else {
                root.escaped();
                event.accepted = root.escapeAccepted;
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            color: Theme.faint
            font: input.font
        }
    }
}
