import QtQuick
import Quickshell
import "../../core"

// Settings as a regular toplevel window: Hyprland tiles it like any other app
// instead of growing it out of the island. Visibility is Sys.settingsOpen.
FloatingWindow {
    id: root

    title: "MacMono Settings"
    color: Theme.ink
    visible: Sys.settingsOpen
    implicitWidth: 1000
    implicitHeight: 760
    minimumSize: Qt.size(880, 600)

    SettingsView {
        anchors.fill: parent
        windowShown: root.visible
    }

    onClosed: Sys.settingsOpen = false
}
