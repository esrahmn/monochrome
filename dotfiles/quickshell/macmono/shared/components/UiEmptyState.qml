import QtQuick
import "../../core"

Column {
    id: root

    property string title: ""
    property string hint: ""

    spacing: Theme.space4

    Text {
        visible: root.title !== ""
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.title
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.fontMd
    }
    Text {
        visible: root.hint !== ""
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.hint
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: Theme.fontSm
    }
}
