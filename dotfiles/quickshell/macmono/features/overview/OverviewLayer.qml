import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overviewWindow
            required property var modelData
            screen: modelData
            visible: Sys.activePanel === "overview" && Sys.activePanelScreen === screen.name
            anchors { top: true; bottom: true; left: true; right: true }
            color: Theme.transparent
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "macmono:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            OverviewPanel {
                anchors.fill: parent
                panelScreen: overviewWindow.screen.name
            }
        }
    }
}
