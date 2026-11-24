import QtQuick
import "../../core"
import "../../shared/components"
import "components"

Item {
    id: root
    anchors.fill: parent
    // Set by SettingsWindow: this view now lives in a toplevel, not an island panel.
    property bool windowShown: false

    readonly property int settingsWidth: 960
    readonly property int settingsHeight: 760
    implicitWidth: settingsWidth
    implicitHeight: settingsHeight
    Item {
        id: win
        anchors.fill: parent
        readonly property bool shown: root.windowShown

        Item {
            id: body
            anchors.fill: parent

            SettingsPanel {
                id: panel
                anchors.fill: parent
                panelShown: win.shown
                onCloseRequested: Sys.settingsOpen = false
            }
        }

        onShownChanged: {
            if (shown) panel.focusPanel();
            else panel.revert();
        }
    }
}
