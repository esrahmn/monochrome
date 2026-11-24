import QtQuick
import QtQuick.Effects
import Quickshell
import "../calendar"
import "../cheatsheet"
import "../clipboard"
import "../controlCenter"
import "../emojiPicker"
import "../launcher"
import "../media"
import "../notifications"
import "../power"
import "../tray"
import "../wallpaper"
import "../../core"
import "../../shared/components"

// Island body: picks the panel, sizes it, and morphs on switches.
Item {
    id: root

    property string screenName: ""
    property string panelName: ""
    property real maxPanelHeight: 700
    property real targetWidth: 0
    property real align: 0.5
    property string displayedPanel: ""
    property string pendingPanel: ""
    property bool revealOpen: false
    property real swapFade: 1

    readonly property real progress: reveal.progress
    readonly property real travel: reveal.travel
    readonly property real widthProgress: widthReveal.progress
    readonly property real widthTravel: widthReveal.travel
    readonly property bool toastMode: displayedPanel === "notifications"
    // Panels that fade their own contents in and out (Cascade) skip the block fade below.
    // Notifications stay out: its toasts already animate themselves.
    readonly property bool selfReveal: ["calendar", "media", "controlCenter", "launcher",
        "clipboard", "emoji", "cheatsheet", "power", "tray", "wallpaper"].indexOf(displayedPanel) >= 0
    // Those panels also get a moment to play their contents out before the body closes around them.
    readonly property int closeHoldMs: 170

    readonly property bool shown: panelName !== "" && (panelName === "notifications"
        || (Sys.activePanel === panelName && Sys.activePanelScreen === screenName))
    readonly property var activeItem: displayedPanel === "launcher" ? launcherLoader.item
        : displayedPanel === "emoji" ? emojiLoader.item : panelLoader.item
    readonly property real contentHeight: activeItem?.implicitHeight ?? 0
    readonly property real desiredWidth: activeItem?.implicitWidth ?? 0
    readonly property real targetHeight: Math.min(contentHeight, Math.max(1, maxPanelHeight))

    readonly property real settledHeight: heightSpring.value
    SpringValue {
        id: heightSpring
        target: root.targetHeight
        springy: root.revealOpen && reveal.progress > 0.98
    }

    implicitHeight: targetHeight
    height: Math.max(0, settledHeight * reveal.progress
        + (reveal.travel > 1 ? Math.min(settledHeight * (reveal.travel - 1), Theme.revealOvershootMax) : 0))

    function panelComponent(name) {
        switch (name) {
        case "calendar": return calendarComponent;
        case "media": return mediaComponent;
        case "controlCenter": return controlCenterComponent;
        case "launcher": return launcherComponent;
        case "clipboard": return clipboardComponent;
        case "emoji": return emojiComponent;
        case "cheatsheet": return cheatsheetComponent;
        case "power": return powerComponent;
        case "tray": return trayComponent;
        case "notifications": return notificationsComponent;
        case "wallpaper": return wallpaperComponent;
        default: return null;
        }
    }

    function closePanel() {
        switch (displayedPanel) {
        case "calendar": Sys.calendarOpen = false; break;
        case "media": Sys.mediaOpen = false; break;
        case "controlCenter": Sys.closeCC(); break;
        case "launcher": Sys.launcherMenuOpen = false; break;
        case "clipboard": Sys.clipboardOpen = false; break;
        case "emoji": Sys.emojiOpen = false; break;
        case "cheatsheet": Sys.cheatOpen = false; break;
        case "power": Sys.powerOpen = false; break;
        case "tray": Sys.trayMenuOpen = false; break;
        case "wallpaper": Sys.wallpaperOpen = false; break;
        }
    }

    function syncPanel() {
        const requested = shown ? panelName : "";
        closeHold.stop();
        if (requested === "") {
            swapAnim.stop();
            swapFade = 1;
            pendingPanel = "";
            if (selfReveal && revealOpen)
                closeHold.start();
            else
                revealOpen = false;
        } else if (requested === displayedPanel) {
            swapAnim.stop();
            swapFade = 1;
            pendingPanel = "";
            revealOpen = true;
        } else if (displayedPanel === "") {
            swapFade = 1;
            displayedPanel = requested;
            revealOpen = true;
        } else if (revealOpen && reveal.progress > 0.9) {
            pendingPanel = requested;
            swapAnim.restart();
        } else {
            pendingPanel = requested;
            revealOpen = false;
        }
    }

    Component { id: calendarComponent; CalendarPanel { panelScreen: root.screenName } }
    Component { id: mediaComponent; MediaPanel { panelScreen: root.screenName } }
    Component { id: controlCenterComponent; ControlCenterPanel { panelScreen: root.screenName } }
    Component { id: launcherComponent; LauncherPanel { panelScreen: root.screenName } }
    Component { id: clipboardComponent; ClipboardPanel { panelScreen: root.screenName } }
    Component { id: emojiComponent; EmojiPanel { panelScreen: root.screenName } }
    Component { id: cheatsheetComponent; CheatsheetPanel { panelScreen: root.screenName } }
    Component { id: powerComponent; PowerPanel { panelScreen: root.screenName } }
    Component { id: trayComponent; TrayPanel { panelScreen: root.screenName } }
    Component { id: notificationsComponent; NotifToasts { panelScreen: root.screenName } }
    Component { id: wallpaperComponent; WallpaperPanel { panelScreen: root.screenName } }

    function finishClose() {
        if (revealOpen || reveal.animating || widthReveal.animating)
            return;
        if (pendingPanel !== "") {
            displayedPanel = pendingPanel;
            pendingPanel = "";
            swapFade = 1;
            revealOpen = true;
        } else if (!shown) {
            displayedPanel = "";
        }
    }

    Reveal {
        id: reveal
        open: root.revealOpen
        openStiff: Theme.islandHeightOpenStiff
        openDamp: Theme.islandHeightOpenDamp
        closeStiff: Theme.islandHeightCloseStiff
        closeDamp: Theme.islandHeightCloseDamp
        anticipate: Theme.islandAnticipate
        anticipateMs: Theme.islandAnticipateMs
        onSettled: (isOpen) => {
            if (!isOpen) root.finishClose();
        }
    }

    Reveal {
        id: widthReveal
        open: root.revealOpen
        openStiff: Theme.islandWidthOpenStiff
        openDamp: Theme.islandWidthOpenDamp
        closeStiff: Theme.islandWidthCloseStiff
        closeDamp: Theme.islandWidthCloseDamp
        onSettled: (isOpen) => {
            if (!isOpen) root.finishClose();
        }
    }

    SequentialAnimation {
        id: swapAnim
        NumberAnimation { target: root; property: "swapFade"; to: 0; duration: Theme.durFast; easing.type: Theme.easeIn }
        ScriptAction {
            script: {
                if (root.pendingPanel !== "") {
                    root.displayedPanel = root.pendingPanel;
                    root.pendingPanel = "";
                }
            }
        }
        NumberAnimation { target: root; property: "swapFade"; to: 1; duration: Theme.durBase; easing.type: Theme.easeOut }
    }

    Timer {
        id: closeHold
        interval: root.closeHoldMs
        onTriggered: if (!root.shown) root.revealOpen = false
    }

    onShownChanged: syncPanel()
    onPanelNameChanged: syncPanel()
    Component.onCompleted: syncPanel()

    Item {
        id: content
        anchors {
            top: parent.top
            topMargin: -Theme.space8 * (1 - reveal.progress)
        }
        x: (root.width - width) * root.align
        width: root.targetWidth > 0 ? root.targetWidth : root.width
        height: root.settledHeight
        readonly property real fade: (root.selfReveal ? 1 : reveal.span(0.2, 0.85)) * root.swapFade
        opacity: fade
        enabled: root.revealOpen
        clip: true
        layer.enabled: Settings.islandBlur && fade < 0.999
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: Theme.islandBlurMax
            blur: 1 - content.fade
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.closePanel();
                event.accepted = true;
            }
        }

        Loader {
            id: panelLoader
            anchors.fill: parent
            visible: root.displayedPanel !== "launcher" && root.displayedPanel !== "emoji"
            sourceComponent: visible ? root.panelComponent(root.displayedPanel) : null
            onLoaded: {
                if ((root.displayedPanel === "power" || root.displayedPanel === "media") && item)
                    item.forceActiveFocus();
            }
        }

        Loader {
            id: launcherLoader
            anchors.fill: parent
            visible: root.displayedPanel === "launcher"
            sourceComponent: visible || item !== null ? launcherComponent : null
        }

        Loader {
            id: emojiLoader
            anchors.fill: parent
            visible: root.displayedPanel === "emoji"
            sourceComponent: visible || item !== null ? emojiComponent : null
        }

    }
}
