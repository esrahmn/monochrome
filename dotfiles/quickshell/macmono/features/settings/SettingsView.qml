import QtQuick
import "../../core"
import "../../shared/components"
import "components"

Item {
    id: root
    anchors.fill: parent
    property string panelScreen: ""

    readonly property int settingsWidth: 960
    readonly property int settingsHeight: 760
    implicitWidth: settingsWidth
    implicitHeight: settingsHeight
    Item {
        id: win
        anchors.fill: parent
        readonly property bool shown: Sys.activePanel === "settings" && Sys.activePanelScreen === root.panelScreen

        Item {
            id: body
            anchors.fill: parent

            SettingsPanel {
                id: panel
                anchors.fill: parent
                onCloseRequested: Sys.settingsOpen = false
            }
        }

        onShownChanged: {
            if (shown) panel.focusPanel();
            else panel.revert();
        }
    }
}
