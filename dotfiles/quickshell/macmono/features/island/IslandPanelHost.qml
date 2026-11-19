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
import "../overview"
import "../power"
import "../settings"
import "../tray"
import "../wallpaper"
import "../../core"
import "../../shared/components"

// The body of the island: what drops out of the header.
// It has no frame of its own. The island (MenuBar) draws the single glass surface and clips to it.
// The host decides which panel is shown, how tall the body is, and how it appears.
//
// Two rules keep it feeling like one object:
//   1. The panel is laid out once at its final width and centered. The island only reveals it,
//      so nothing is squeezed or re-wrapped while the island grows.
//   2. Switching panels morphs in place (fade out, resize, fade in). The island never closes in between.
Item {
    id: root

    property string screenName: ""
    property string panelName: ""
    property real maxPanelHeight: 700
    // Final width of the island while a body is shown. Set by the island.
    property real targetWidth: 0
    // Where the body hangs off the bar: 0 = left edge fixed, 0.5 = centered, 1 = right edge fixed.
    // The panel is laid out at its final width and held still on that side while the body grows around it.
    property real align: 0.5
    property string displayedPanel: ""
    property string pendingPanel: ""
    property bool revealOpen: false
    // 1 = content visible. Dips to 0 while the island morphs from one panel to another.
    property real swapFade: 1

    // The island reads these so its width and height follow the same spring.
    readonly property real progress: reveal.progress
    readonly property real travel: reveal.travel
    // The width has its own spring: faster on the way out, slower on the way back (see Theme).
    readonly property real widthProgress: widthReveal.progress
    readonly property real widthTravel: widthReveal.travel
    // Notifications are a transient body: no shortcut, no focus, no dismiss layer.
    readonly property bool toastMode: displayedPanel === "notifications"

    readonly property bool shown: panelName !== "" && (panelName === "notifications"
        || (Sys.activePanel === panelName && Sys.activePanelScreen === screenName))
    readonly property var activeItem: displayedPanel === "launcher" ? launcherLoader.item
        : displayedPanel === "emoji" ? emojiLoader.item
        : displayedPanel === "overview" ? overviewLoader.item : panelLoader.item
    readonly property real contentHeight: activeItem?.implicitHeight ?? 0
    readonly property real desiredWidth: activeItem?.implicitWidth ?? 0
    readonly property real targetHeight: Math.min(contentHeight, Math.max(1, maxPanelHeight))

    // Follows the panel's own height when it grows or shrinks while open (Wi-Fi list, media starting,
    // a switch to another panel), on a spring so it settles with the same give as the opening. While the
    // drawer itself is opening or closing the value is set directly, so nothing animates twice.
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
        case "settings": return settingsComponent;
        case "clipboard": return clipboardComponent;
        case "emoji": return emojiComponent;
        case "cheatsheet": return cheatsheetComponent;
        case "power": return powerComponent;
        case "tray": return trayComponent;
        case "notifications": return notificationsComponent;
        case "wallpaper": return wallpaperComponent;
        case "overview": return overviewComponent;
        default: return null;
        }
    }

    function closePanel() {
        switch (displayedPanel) {
        case "calendar": Sys.calendarOpen = false; break;
        case "media": Sys.mediaOpen = false; break;
        case "controlCenter": Sys.closeCC(); break;
        case "launcher": Sys.launcherMenuOpen = false; break;
        case "settings": Sys.settingsOpen = false; break;
        case "clipboard": Sys.clipboardOpen = false; break;
        case "emoji": Sys.emojiOpen = false; break;
        case "cheatsheet": Sys.cheatOpen = false; break;
        case "power": Sys.powerOpen = false; break;
        case "tray": Sys.trayMenuOpen = false; break;
        case "wallpaper": Sys.wallpaperOpen = false; break;
        case "overview": Sys.overviewOpen = false; break;
        }
    }

    function syncPanel() {
        const requested = shown ? panelName : "";
        if (requested === "") {
            swapAnim.stop();
            swapFade = 1;
            pendingPanel = "";
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
            // Open and switching: morph in place.
            pendingPanel = requested;
            swapAnim.restart();
        } else {
            // Still opening or already closing: let it finish, then open the new one.
            pendingPanel = requested;
            revealOpen = false;
        }
    }

    Component { id: calendarComponent; CalendarPanel { panelScreen: root.screenName } }
    Component { id: mediaComponent; MediaPanel { panelScreen: root.screenName } }
    Component { id: controlCenterComponent; ControlCenterPanel { panelScreen: root.screenName } }
    Component { id: launcherComponent; LauncherPanel { panelScreen: root.screenName } }
    Component { id: settingsComponent; SettingsView { panelScreen: root.screenName } }
    Component { id: clipboardComponent; ClipboardPanel { panelScreen: root.screenName } }
    Component { id: emojiComponent; EmojiPanel { panelScreen: root.screenName } }
    Component { id: cheatsheetComponent; CheatsheetPanel { panelScreen: root.screenName } }
    Component { id: powerComponent; PowerPanel { panelScreen: root.screenName } }
    Component { id: trayComponent; TrayPanel { panelScreen: root.screenName } }
    Component { id: notificationsComponent; NotifToasts { panelScreen: root.screenName } }
    Component { id: wallpaperComponent; WallpaperPanel { panelScreen: root.screenName } }
    Component { id: overviewComponent; OverviewPanel { panelScreen: root.screenName } }

    // Closed for real only when both springs are at rest (the width trails the height on the way back).
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

    // Height spring. It also paces the content fade. Softer and bouncier on the way out, quicker on the way back.
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

    // Width spring: leads on the way out, trails on the way back, so the shape stretches instead of scaling.
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

    // Old content fades out, the panel is swapped, new content fades in while the island resizes.
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

    onShownChanged: syncPanel()
    onPanelNameChanged: syncPanel()
    Component.onCompleted: syncPanel()

    Item {
        id: content
        anchors {
            top: parent.top
            // Slides down out of the header while it fades in.
            topMargin: -Theme.space8 * (1 - reveal.progress)
        }
        x: (root.width - width) * root.align
        // Final width, not the island's current width (see rule 1 above).
        width: root.targetWidth > 0 ? root.targetWidth : root.width
        height: root.settledHeight
        // The shape opens first, the content arrives a beat later and comes into focus as it does.
        // 0 = hidden and blurred, 1 = settled. It also dips while one panel morphs into another.
        readonly property real fade: reveal.span(0.2, 0.85) * root.swapFade
        opacity: fade
        enabled: root.revealOpen
        clip: true
        // The blur layer exists only while the content is still arriving: once settled it is a plain
        // item again, so a panel that stays open costs nothing.
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
            visible: root.displayedPanel !== "launcher" && root.displayedPanel !== "emoji" && root.displayedPanel !== "overview"
            sourceComponent: visible ? root.panelComponent(root.displayedPanel) : null
            onLoaded: {
                if ((root.displayedPanel === "power" || root.displayedPanel === "media" || root.displayedPanel === "overview") && item)
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

        // The overview is built once and then only hidden. Rebuilding it on every open meant
        // recreating every cell and window preview. While hidden it holds no capture streams.
        Loader {
            id: overviewLoader
            anchors.fill: parent
            visible: root.displayedPanel === "overview"
            sourceComponent: visible || item !== null ? overviewComponent : null
            onVisibleChanged: if (visible && item) item.forceActiveFocus()
            onLoaded: if (item) item.forceActiveFocus()
        }
    }
}
