import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import "../../core"
import "../../shared/components"
import "../island"
import "../osd"

// Full-width bar that is also the island; the body lives in IslandPanelHost.
Scope {
    id: root
    readonly property int islandHeight: Theme.barHeight
    readonly property int islandMediaMinWidth: 72
    readonly property int menubarCellHeight: 16
    readonly property int menubarTrayItem: 20
    readonly property int menubarTitleMaxWidth: 160
    readonly property int wsDotWide: 20
    readonly property int wsDotNarrow: 7
    readonly property int notifDotSize: 8
    readonly property var hiddenTrayIds: ["nm-applet"]
    function trayHidden(item) {
        const id = String(item?.id ?? "").toLowerCase();
        return root.hiddenTrayIds.some(h => id.indexOf(h) >= 0);
    }

    property string osdKind: "volume"
    property string osdScreen: ""
    property bool osdShown: false
    property bool osdReady: false

    Component.onCompleted: Sys.refreshHypr()

    Timer { interval: Settings.osdStartupGraceMs; running: true; onTriggered: root.osdReady = true }
    Timer { id: osdHideTimer; interval: Settings.osdHideMs; onTriggered: root.osdShown = false }

    function popOsd(kind) {
        if (!osdReady || Sys.ccOpen || Sys.capturing)
            return;
        osdKind = kind;
        osdScreen = Sys.focusedScreenName();
        osdShown = true;
        osdHideTimer.restart();
    }

    Connections {
        target: Sys
        function onVolumeChanged() { root.popOsd("volume"); }
        function onMutedChanged() { root.popOsd("volume"); }
        function onBrightnessChanged() { root.popOsd("brightness"); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            visible: Sys.barVisible || bar.childPanelOpen || bar.osdContentVisible
                || bar.toastActive || islandPanelHost.progress > 0.001 || islandPanelHost.widthProgress > 0.001
            anchors { top: true; left: true; right: true }
            margins { top: Theme.barMargin }
            implicitHeight: bar.screen.height - Theme.barMargin
            exclusiveZone: root.islandHeight + Theme.barMargin
            color: Theme.transparent
            mask: Region {
                item: header
                Region { item: bodyClip }
                Region { item: dismissLayer }
            }
            WlrLayershell.namespace: "macmono:menubar"
            WlrLayershell.layer: (Sys.wallpaperOpen && Sys.wallpaperScreen === bar.screen.name)
                || islandPanelHost.displayedPanel === "wallpaper" ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.keyboardFocus: !bar.childPanelOpen ? WlrKeyboardFocus.None
                : Sys.activePanel === "controlCenter" && islandPanelHost.activeItem?.typing !== true
                    ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive

            IdleInhibitor { window: bar; enabled: Sys.keepAwake }

            property bool hoverBody: false
            onHoverBodyChanged: Sys.toastHover = hoverBody
            readonly property bool childPanelOpen:
                Sys.activePanel !== "" && Sys.activePanelScreen === bar.screen.name
            readonly property bool osdActive: root.osdShown && root.osdScreen === bar.screen.name
            property real osdMix: osdActive ? 1 : 0
            Behavior on osdMix { Tween { duration: Theme.durBase } }
            readonly property bool osdContentVisible: osdActive || osdMix > 0.01
            readonly property bool toastActive: bar.screen.name === (Quickshell.screens[0]?.name ?? bar.screen.name)
                && Sys.toastCount > 0
            readonly property var mediaPlayer: Sys.mediaPlayer(Mpris.players.values, -1)
            readonly property var activeTop: ToplevelManager.activeToplevel
            readonly property string appName: {
                const id = activeTop?.appId ?? "";
                if (!id) return "Desktop";
                const parts = id.split(".");
                const n = parts[parts.length - 1];
                return n.charAt(0).toUpperCase() + n.slice(1);
            }
            readonly property string timeLabel: Sys.clockLabel
            readonly property string dateLabel: Qt.formatDateTime(Sys.now, "ddd d MMM")

            Item {
                id: dismissLayer
                width: bar.childPanelOpen ? bar.width : 0
                height: bar.childPanelOpen ? bar.height : 0

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    enabled: bar.childPanelOpen && !Sys.capturing && islandPanelHost.activeItem?.holdOpen !== true
                    onPressed: islandPanelHost.closePanel()
                }
            }

            Item {
                id: island

                readonly property int sidePad: Theme.islandSidePad
                readonly property int zoneGap: Theme.islandZoneGap
                readonly property real barRadius: Math.min(Theme.radiusPanel, root.islandHeight / 2)

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: bar.width - Theme.barMargin * 2
                height: root.islandHeight + islandPanelHost.height

                readonly property real dateFull: Settings.clockDate ? dateText.implicitWidth + Theme.space8 : 0
                readonly property real clockNatural: clockText.implicitWidth + dateFull
                readonly property real centerReserve: Math.max(clockNatural, osdIndicator.implicitWidth)
                readonly property real laneWidth: Math.max(0, (width - centerReserve - sidePad * 2 - zoneGap * 2) / 2)
                readonly property int trayCount: SystemTray.items.values.filter(i => !root.trayHidden(i)).length
                readonly property real trayNatural: trayCount > 0
                    ? trayCount * root.menubarTrayItem + (trayCount - 1) * Theme.space12 : 0

                readonly property real bodyHeight: islandPanelHost.height
                readonly property real maxBodyWidth: Math.max(0,
                    (width - 2 * (barRadius + Theme.islandFillet + Theme.space16)) / 1.04)
                readonly property real panelWidthTarget: Math.min(maxBodyWidth,
                    Math.max(Theme.islandCompactMinWidth, islandPanelHost.desiredWidth))
                readonly property real bodyBase: Math.min(panelWidthTarget,
                    Math.max(Theme.islandCompactMinWidth, centerReserve + sidePad * 2))
                readonly property real panelWidth: panelWidthSpring.value
                SpringValue {
                    id: panelWidthSpring
                    target: island.panelWidthTarget
                    springy: islandPanelHost.revealOpen && islandPanelHost.progress > 0.98
                }
                readonly property real panelT: Math.min(1.04, Math.max(0, islandPanelHost.widthTravel))
                readonly property real bodyWidth: bodyBase + (panelWidth - bodyBase) * panelT
                readonly property real bodyScale: Math.min(1, bodyHeight / (Theme.islandFillet + Theme.radiusPanel))
                readonly property real filletRadius: Theme.islandFillet * bodyScale
                readonly property real bodyRadius: Math.min(Theme.radiusPanel * bodyScale, bodyWidth / 2)

                readonly property real edgeInset: barRadius + Theme.islandFillet + Theme.space4
                readonly property var placeTarget: {
                    const edge = { p: width - sidePad, a: 1 };
                    switch (islandPanelHost.displayedPanel) {
                    case "launcher": return { p: launcherButton.x - Theme.space8, a: 0 };
                    case "controlCenter": return edge;
                    case "media": return miniMediaArea.width > 0
                        ? { p: rightLane.x + miniMediaArea.x + miniMediaArea.width / 2, a: 0.5 } : edge;
                    case "tray": return trayRow.visible
                        ? { p: rightLane.x + trayRow.x + trayRow.width / 2, a: 0.5 } : edge;
                    default: return { p: width / 2, a: 0.5 };
                    }
                }
                SpringValue {
                    id: placeXSpring
                    target: island.placeTarget.p
                    springy: islandPanelHost.revealOpen && islandPanelHost.progress > 0.98
                }
                property real alignA: placeTarget.a
                Behavior on alignA {
                    enabled: islandPanelHost.revealOpen && islandPanelHost.progress > 0.98
                    Tween { duration: Theme.durBase }
                }
                readonly property real alignNow: Math.max(0, Math.min(1, alignA))
                readonly property real bodyLeft: Math.max(edgeInset,
                    Math.min(placeXSpring.value - alignNow * bodyWidth, width - edgeInset - bodyWidth))

                Shape {
                    id: surface
                    anchors.fill: parent
                    z: 0
                    preferredRendererType: Shape.CurveRenderer

                    readonly property string pathData: {
                        const n = (v) => v.toFixed(2);
                        const W = island.width;
                        const H = root.islandHeight;
                        const R = Math.max(0.01, island.barRadius);
                        const bw = island.bodyWidth;
                        const f = Math.max(0.01, island.filletRadius);
                        const rp = Math.max(0.01, island.bodyRadius);
                        const x0 = island.bodyLeft;
                        const x1 = x0 + bw;
                        const yb = H + Math.max(0, island.bodyHeight);
                        if (island.bodyHeight < 0.5) {
                            return "M " + n(R) + " 0"
                                + " L " + n(W - R) + " 0"
                                + " A " + n(R) + " " + n(R) + " 0 0 1 " + n(W) + " " + n(R)
                                + " L " + n(W) + " " + n(H - R)
                                + " A " + n(R) + " " + n(R) + " 0 0 1 " + n(W - R) + " " + n(H)
                                + " L " + n(R) + " " + n(H)
                                + " A " + n(R) + " " + n(R) + " 0 0 1 0 " + n(H - R)
                                + " L 0 " + n(R)
                                + " A " + n(R) + " " + n(R) + " 0 0 1 " + n(R) + " 0 Z";
                        }
                        return "M " + n(R) + " 0"
                            + " L " + n(W - R) + " 0"
                            + " A " + n(R) + " " + n(R) + " 0 0 1 " + n(W) + " " + n(R)
                            + " L " + n(W) + " " + n(H - R)
                            + " A " + n(R) + " " + n(R) + " 0 0 1 " + n(W - R) + " " + n(H)
                            + " L " + n(x1 + f) + " " + n(H)
                            + " A " + n(f) + " " + n(f) + " 0 0 0 " + n(x1) + " " + n(H + f)
                            + " L " + n(x1) + " " + n(yb - rp)
                            + " A " + n(rp) + " " + n(rp) + " 0 0 1 " + n(x1 - rp) + " " + n(yb)
                            + " L " + n(x0 + rp) + " " + n(yb)
                            + " A " + n(rp) + " " + n(rp) + " 0 0 1 " + n(x0) + " " + n(yb - rp)
                            + " L " + n(x0) + " " + n(H + f)
                            + " A " + n(f) + " " + n(f) + " 0 0 0 " + n(x0 - f) + " " + n(H)
                            + " L " + n(R) + " " + n(H)
                            + " A " + n(R) + " " + n(R) + " 0 0 1 0 " + n(H - R)
                            + " L 0 " + n(R)
                            + " A " + n(R) + " " + n(R) + " 0 0 1 " + n(R) + " 0 Z";
                    }

                    ShapePath {
                        fillColor: Theme.panel
                        strokeColor: Theme.transparent
                        strokeWidth: -1
                        PathSvg { path: surface.pathData }
                    }
                    ShapePath {
                        fillColor: Theme.transparent
                        strokeColor: Theme.line
                        strokeWidth: Theme.borderThin
                        PathSvg { path: surface.pathData }
                    }
                }

                Item {
                    id: header
                    z: 1
                    width: island.width
                    height: root.islandHeight

                    MouseArea {
                        id: islandGestures
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons

                        property real wheelAcc: 0

                        onClicked: (mouse) => {
                            if (!Settings.islandGestures) return;
                            if (mouse.button === Qt.MiddleButton) Sys.setMuted(!Sys.muted);
                            else if (mouse.button === Qt.RightButton) Sys.toggleCC(bar.screen.name);
                        }
                        onWheel: (wheel) => {
                            if (!Settings.islandGestures || wheel.angleDelta.y === 0) {
                                wheel.accepted = false;
                                return;
                            }
                            wheelAcc += wheel.angleDelta.y;
                            const notches = Math.trunc(wheelAcc / 120);
                            if (notches === 0) return;
                            wheelAcc -= notches * 120;
                            Sys.setVolume(Sys.volume + notches * Settings.islandScrollStep);
                        }
                    }

                    Item {
                        id: leftLane
                        anchors { left: parent.left; top: parent.top }
                        width: island.sidePad + island.laneWidth
                        height: root.islandHeight
                        clip: true

                        Item {
                            id: launcherButton
                            x: island.sidePad
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.iconLg
                            height: Theme.iconLg

                            readonly property bool menuOpen: Sys.launcherMenuOpen && Sys.launcherMenuScreen === bar.screen.name

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -Theme.space8
                                radius: height / 2
                                color: Theme.tile
                                visible: launcherButton.menuOpen
                            }

                            Glyph {
                                anchors.fill: parent
                                name: "enso"
                                color: Theme.text
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -Theme.space8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Sys.toggleLauncherMenu(bar.screen.name)
                            }
                        }

                        Item {
                            id: ws
                            x: launcherButton.x + launcherButton.width + Theme.space12
                            anchors.verticalCenter: parent.verticalCenter
                            width: wsRow.width
                            height: root.menubarCellHeight
                            readonly property int count: Math.min(Settings.menubarWorkspaceMax, Math.max(Settings.menubarWorkspaceMin, Hyprland.focusedWorkspace?.id ?? 0,
                                                                               ...Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0 && id <= Settings.menubarWorkspaceMax)))

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -Theme.space8
                                onWheel: (e) => {
                                    Hyprland.dispatch("hl.dsp.focus({workspace = \"r" + (e.angleDelta.y > 0 ? "-1" : "+1") + "\"})");
                                }
                            }

                            Row {
                                id: wsRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Repeater {
                                    model: ws.count
                                    delegate: Item {
                                        id: cell
                                        required property int index
                                        readonly property int num: index + 1
                                        readonly property bool active: Hyprland.focusedWorkspace?.id === num
                                        readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === num)
                                        readonly property real dotW: active ? root.wsDotWide : root.wsDotNarrow
                                        readonly property real gap: Theme.space4

                                        height: root.menubarCellHeight
                                        width: dotW + (index < ws.count - 1 ? gap : 0)

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: cell.dotW
                                            height: cell.active ? 8 : 7
                                            radius: height / 2
                                            color: cell.active ? Theme.accent : (cell.occupied ? Theme.dim : Theme.faint)
                                            Behavior on color { TweenColor {} }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -Theme.space2
                                            onClicked: Hyprland.dispatch("hl.dsp.focus({workspace = " + cell.num + "})")
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            id: appTitleBox
                            x: ws.x + ws.width + Theme.space12
                            anchors.verticalCenter: parent.verticalCenter
                            readonly property real room: leftLane.width - x
                            width: Math.max(0, Math.min(appTitle.implicitWidth, root.menubarTitleMaxWidth, room))
                            height: appTitle.implicitHeight
                            opacity: Math.max(0, Math.min(1, (room - 24) / 48))
                            Text {
                                id: appTitle
                                width: parent.width
                                elide: Text.ElideRight
                                text: bar.appName
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontMd
                                font.weight: Theme.weightSemibold
                            }
                        }
                    }

                    Item {
                        id: rightLane
                        anchors { right: parent.right; top: parent.top }
                        width: island.sidePad + island.laneWidth
                        height: root.islandHeight

                        readonly property real rightEdge: width - island.sidePad
                        readonly property real afterStatusX: rightEdge - statusArea.width
                        readonly property real trayW: island.trayNatural > 0 && afterStatusX - Theme.space12 >= island.trayNatural
                            ? island.trayNatural : 0
                        readonly property real trayX: afterStatusX - (trayW > 0 ? Theme.space12 + trayW : 0)
                        readonly property real clockEdgeX: (island.clockNatural - island.centerReserve) / 2 - island.zoneGap
                        readonly property real mediaCenterX: (clockEdgeX + trayX) / 2
                        readonly property real mediaFree: trayX - clockEdgeX - Theme.space12 * 2
                        readonly property real mediaW: bar.mediaPlayer === null ? 0
                            : (mediaFree >= root.islandMediaMinWidth ? Math.min(Sys.mediaPopupWidth, island.maxBodyWidth, mediaFree) : 0)

                        MouseArea {
                            id: miniMediaArea
                            readonly property var player: bar.mediaPlayer
                            readonly property bool waveOn: Boolean(player?.isPlaying) && Settings.visualizerEnabled && Settings.visualizerInBar
                            x: Math.round(rightLane.mediaCenterX - width / 2)
                            anchors.verticalCenter: parent.verticalCenter
                            width: rightLane.mediaW
                            height: root.islandHeight - Theme.space8
                            visible: width > 0
                            clip: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Sys.toggleMedia(bar.screen.name)

                            CavaWave {
                                anchors.fill: parent
                                opacity: miniMediaArea.waveOn ? 1 - bar.osdMix : 0
                                visible: opacity > 0
                                levels: Sys.mediaVisualizerLevels
                                fillOpacity: 0.10
                                cornerRadius: 0
                            }
                            Glyph {
                                anchors.centerIn: parent
                                width: Theme.iconSm
                                height: Theme.iconSm
                                name: "music"
                                color: Theme.dim
                                visible: !miniMediaArea.waveOn
                            }
                        }

                        Row {
                            id: trayRow
                            x: rightLane.trayX
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.space12
                            visible: rightLane.trayW > 0
                            layer.enabled: visible
                            layer.effect: MultiEffect { saturation: -1.0 }
                            Repeater {
                                model: SystemTray.items
                                delegate: MouseArea {
                                    id: trayItem
                                    required property var modelData
                                    visible: !root.trayHidden(modelData)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: root.menubarTrayItem
                                    height: root.menubarTrayItem
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    onClicked: (e) => {
                                        if (e.button === Qt.MiddleButton) { modelData.secondaryActivate(); return; }
                                        if (e.button === Qt.LeftButton && !modelData.onlyMenu) { modelData.activate(); return; }
                                        if (modelData.hasMenu) Sys.openTrayMenu(modelData, bar.screen.name);
                                    }
                                    onWheel: (w) => modelData.scroll(w.angleDelta.y, false)
                                    IconImage {
                                        anchors.fill: parent
                                        source: trayItem.modelData.icon
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: statusArea
                            x: rightLane.rightEdge - width
                            anchors.verticalCenter: parent.verticalCenter
                            width: statusRow.width + Theme.space8
                            height: root.islandHeight
                            onClicked: Sys.toggleCC(bar.screen.name)

                            Row {
                                id: statusRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.space12

                                Row {
                                    id: privacyRow
                                    visible: Settings.barIndicators
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.space8

                                    MouseArea {
                                        id: recStop
                                        readonly property bool ours: Sys.recActive
                                        visible: Sys.recActive || Sys.recording
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: ours ? recStopRow.width + Theme.space16 : Theme.iconSm
                                        height: ours ? 26 : Theme.iconSm
                                        enabled: ours
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Sys.recordStop()

                                        Rectangle {
                                            anchors.fill: parent
                                            visible: recStop.ours
                                            radius: height / 2
                                            color: recStop.containsMouse ? Theme.tileHover : Theme.tile
                                            Behavior on color { TweenColor { duration: Theme.durFast } }
                                        }
                                        Row {
                                            id: recStopRow
                                            visible: recStop.ours
                                            anchors.centerIn: parent
                                            spacing: Theme.space8

                                            PulseDot {
                                                anchors.verticalCenter: parent.verticalCenter
                                                size: 8
                                                pulsing: recStop.ours && recStop.visible
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: Sys.recLabel
                                                color: Theme.text
                                                font.family: Theme.font
                                                font.pixelSize: Theme.fontSm
                                                font.weight: Theme.weightSemibold
                                                font.features: ({ "tnum": 1 })
                                            }
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 8
                                                height: 8
                                                radius: 2
                                                color: Theme.text
                                            }
                                        }
                                        Glyph {
                                            visible: !recStop.ours
                                            anchors.centerIn: parent
                                            width: Theme.iconSm
                                            height: Theme.iconSm
                                            name: "record"
                                            color: Theme.text
                                        }
                                    }
                                    Glyph {
                                        visible: Sys.micInUse
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Theme.iconMd; height: Theme.iconMd
                                        name: Sys.micMuted ? "mic-off" : "mic"
                                        color: Theme.text
                                    }
                                    Glyph {
                                        visible: Sys.camInUse
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Theme.iconMd; height: Theme.iconMd
                                        name: "camera"
                                        color: Theme.text
                                    }
                                    Glyph {
                                        visible: Sys.dnd
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Theme.iconMd; height: Theme.iconMd
                                        name: "bell-off"
                                        color: Theme.dim
                                    }
                                }

                                Glyph {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Theme.iconLg; height: Theme.iconLg
                                    name: Sys.wifiGlyph
                                    color: Sys.wifiOn ? Theme.text : Theme.dim
                                }

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    BatteryReadout {
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Item {
                                        id: unreadDot
                                        property real show: Sys.notifUnread > 0 ? 1 : 0
                                        Behavior on show { Tween {} }
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: show > 0.01
                                        width: (Theme.space8 + root.notifDotSize) * show
                                        height: root.notifDotSize
                                        opacity: show
                                        clip: true

                                        Rectangle {
                                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                            width: root.notifDotSize
                                            height: root.notifDotSize
                                            radius: width / 2
                                            color: Theme.accent
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: centerLane
                        z: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        width: bar.osdContentVisible ? Math.max(osdIndicator.implicitWidth, clockGroup.implicitWidth) : clockGroup.implicitWidth
                        height: root.islandHeight

                        MouseArea {
                            anchors.fill: parent
                            enabled: !bar.osdContentVisible
                            onClicked: Sys.toggleCalendar(bar.screen.name)
                        }

                        Osd {
                            id: osdIndicator
                            anchors.centerIn: parent
                            opacity: bar.osdMix
                            visible: opacity > 0.01
                            layer.enabled: Settings.islandBlur && opacity > 0.01 && opacity < 0.999
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blurMax: Theme.islandBlurMax
                                blur: (1 - osdIndicator.opacity) * Theme.islandLaneBlur
                            }
                            kind: root.osdKind
                            level: root.osdKind === "volume" ? (Sys.muted ? 0 : Math.min(1, Sys.volume)) : Sys.brightness
                        }

                        Row {
                            id: clockGroup
                            anchors.centerIn: parent
                            opacity: 1 - bar.osdMix
                            visible: opacity > 0.01
                            layer.enabled: Settings.islandBlur && bar.osdMix > 0.01 && bar.osdMix < 0.999
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blurMax: Theme.islandBlurMax
                                blur: bar.osdMix * Theme.islandSlotBlur
                            }
                            spacing: 0

                            Item {
                                id: dateBox
                                anchors.verticalCenter: parent.verticalCenter
                                width: island.dateFull * (1 - bar.osdMix)
                                height: dateText.implicitHeight
                                clip: true
                                Text {
                                    id: dateText
                                    anchors { right: parent.right; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                                    text: bar.dateLabel
                                    color: Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontMd
                                    font.weight: Theme.weightMedium
                                }
                            }

                            Text {
                                id: clockText
                                anchors.verticalCenter: parent.verticalCenter
                                text: bar.timeLabel
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontLg
                                font.weight: Theme.weightSemibold
                                font.features: ({ "tnum": 1 })
                            }
                        }
                    }
                }

                ClippingRectangle {
                    id: bodyClip
                    z: 1
                    x: island.bodyLeft
                    y: root.islandHeight
                    width: island.bodyWidth
                    height: islandPanelHost.height
                    color: Theme.transparent
                    topLeftRadius: 0
                    topRightRadius: 0
                    bottomLeftRadius: island.bodyRadius
                    bottomRightRadius: island.bodyRadius

                    HoverHandler { onHoveredChanged: bar.hoverBody = hovered }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                    }

                    IslandPanelHost {
                        id: islandPanelHost
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        screenName: bar.screen.name
                        panelName: bar.childPanelOpen ? Sys.activePanel : (bar.toastActive ? "notifications" : "")
                        targetWidth: island.panelWidthTarget
                        align: island.alignNow
                        maxPanelHeight: Math.max(1, bar.screen.height - Theme.barMargin - root.islandHeight - Theme.space16)
                    }
                }
            }
        }
    }
}
