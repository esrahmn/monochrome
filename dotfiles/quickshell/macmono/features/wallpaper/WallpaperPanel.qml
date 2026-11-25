import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../core"
import "../../shared/components"

Item {
    id: root

    property string panelScreen: ""

    readonly property int wpWidth: 880
    readonly property int wpStripHeight: 128
    readonly property int wpControlsHeight: 32
    readonly property int wpCloseDelay: 170
    readonly property int wpCellWidth: 172
    readonly property int wpThumbWidth: 160
    readonly property int wpThumbHeight: 100
    readonly property int wpBadgeHeight: 18
    readonly property real wpPickedScale: 1.08

    implicitWidth: wpWidth
    implicitHeight: Theme.space16 * 2 + wpControlsHeight + Theme.space12 + wpStripHeight

    property string folder: ""
    property string selPath: ""
    property string previousWallpaper: ""
    property bool keeping: false
    property real wheelAcc: 0
    property string hoverPath: ""
    property bool stripAnimated: false

    readonly property bool panelActive: Sys.activePanel === "wallpaper" && Sys.activePanelScreen === panelScreen
    // Controls, strip and empty state come in one after another when the panel opens.
    Cascade { id: stagger; open: root.panelActive; count: 3; step: 60 }
    function intro(order) { return stagger.fade(order); }
    function rise(order) { return Theme.staggerRise * (1 - stagger.fade(order)); }

    readonly property var folders: {
        const seen = {};
        const out = [];
        for (const p of Sys.wallpapers) {
            const d = dirOf(p);
            if (!seen[d]) { seen[d] = true; out.push(d); }
        }
        return out;
    }

    property var pics: []
    readonly property int selIndex: pics.indexOf(selPath)

    function rebuildPics() {
        const next = folder === "" ? Sys.wallpapers : Sys.wallpapers.filter(p => dirOf(p) === folder);
        const same = next.length === pics.length && next.every((p, i) => p === pics[i]);
        if (!same) pics = next;
    }
    onFolderChanged: rebuildPics()
    onPicsChanged: {
        stripAnimated = false;
        Qt.callLater(() => { root.syncStrip(); root.stripAnimated = true; });
    }

    function dirOf(p) { return p.substring(0, p.lastIndexOf("/")); }
    function baseOf(p) { return p.substring(p.lastIndexOf("/") + 1); }

    function select(p) {
        if (keeping) return;
        selPath = p;
        hoverPath = "";
        previewTimer.restart();
        keys.forceActiveFocus();
    }
    function hover(p) {
        if (keeping || hoverPath === p) return;
        hoverPath = p;
        previewTimer.restart();
    }
    function step(d) {
        if (pics.length === 0) return;
        let i = selIndex;
        if (i < 0) i = d > 0 ? -1 : pics.length;
        i = Math.max(0, Math.min(pics.length - 1, i + d));
        if (pics[i] !== selPath) select(pics[i]);
    }
    function shuffle() {
        if (pics.length === 0) return;
        if (pics.length === 1) { select(pics[0]); return; }
        let p = selPath;
        while (p === selPath) p = pics[Math.floor(Math.random() * pics.length)];
        select(p);
    }
    function setFolder(f) {
        folder = f;
        if (pics.indexOf(selPath) < 0 && pics.length > 0) select(pics[0]);
    }
    function syncStrip() {
        strip.currentIndex = selIndex;
        if (selIndex >= 0) strip.positionViewAtIndex(selIndex, ListView.Center);
    }

    function keep() {
        if (keeping) return;
        if (selPath === "") { Sys.wallpaperOpen = false; return; }
        keeping = true;
        previousWallpaper = Sys.wallpaper;
        if (selPath !== Sys.wallpaper) {
            Sys.wallpaper = selPath;
            readyTimeout.restart();
            if (Sys.wallpaperReady) finishKeep();
            return;
        }
        finishKeep();
    }
    function finishKeep() {
        if (!keeping || Sys.wallpaper !== selPath) return;
        readyTimeout.stop();
        Sys.saveState("wallpaper", selPath);
        keeping = false;
        closeTimer.restart();
    }
    function failKeep() {
        if (!keeping) return;
        readyTimeout.stop();
        keeping = false;
        if (Sys.wallpaper === selPath) Sys.wallpaper = previousWallpaper;
        Quickshell.execDetached(["notify-send", "-a", "Wallpaper", "-u", "critical",
            "Wallpaper failed to load", "Previous wallpaper restored. Check the image file you selected."]);
    }

    Timer {
        id: previewTimer
        interval: Settings.wallpaperPreviewDebounceMs
        onTriggered: Sys.wallpaperPreview = root.hoverPath !== "" ? root.hoverPath : root.selPath
    }
    Timer { id: closeTimer; interval: root.wpCloseDelay; onTriggered: Sys.wallpaperOpen = false }
    Timer {
        id: readyTimeout
        interval: Settings.wallpaperReadyTimeoutMs
        onTriggered: {
            if (Sys.wallpaperLoadError === "" && Sys.wallpaperReadyScreens.length > 0) root.finishKeep();
            else root.failKeep();
        }
    }

    onSelIndexChanged: strip.currentIndex = selIndex

    Connections {
        target: Sys
        function onWallpapersChanged() {
            root.rebuildPics();
            if (root.selPath === "" && Sys.wallpapers.length > 0) root.select(Sys.wallpapers[0]);
        }
        function onWallpaperReadyChanged() {
            if (root.keeping && Sys.wallpaperReady) root.finishKeep();
        }
        function onWallpaperLoadErrorChanged() {
            if (root.keeping && Sys.wallpaperLoadError === root.selPath) root.failKeep();
        }
        function onWallpaperOpenChanged() {
            if (Sys.wallpaperOpen) return;
            if (root.keeping && Sys.wallpaper === root.selPath) Sys.wallpaper = root.previousWallpaper;
            root.keeping = false;
            readyTimeout.stop();
            closeTimer.stop();
            previewTimer.stop();
        }
    }

    Component.onCompleted: {
        folder = "";
        rebuildPics();
        selPath = Sys.wallpaper !== "" ? Sys.wallpaper : (Sys.wallpapers.length > 0 ? Sys.wallpapers[0] : "");
        Sys.wallpaperPreview = selPath;
        keys.forceActiveFocus();
        Qt.callLater(() => { root.syncStrip(); root.stripAnimated = true; });
    }

    Item {
        id: keys
        focus: true
        anchors.fill: parent
        Keys.onPressed: (e) => {
            switch (e.key) {
            case Qt.Key_Escape: Sys.wallpaperOpen = false; break;
            case Qt.Key_Return:
            case Qt.Key_Enter:  root.keep(); break;
            case Qt.Key_Left:
            case Qt.Key_H:      root.step(-1); break;
            case Qt.Key_Right:
            case Qt.Key_L:      root.step(1); break;
            case Qt.Key_Home:   if (root.pics.length) root.select(root.pics[0]); break;
            case Qt.Key_End:    if (root.pics.length) root.select(root.pics[root.pics.length - 1]); break;
            case Qt.Key_R:      root.shuffle(); break;
            case Qt.Key_M:      Sys.setWallpaperMono(!Sys.wallpaperMono); break;
            default: return;
            }
            e.accepted = true;
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: Theme.space16 }
        spacing: Theme.space12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.wpControlsHeight
            spacing: Theme.space16
            opacity: root.intro(0)
            scale: 0.98 + 0.02 * stagger.back(0)
            transform: Translate { y: root.rise(0) }

            Text {
                Layout.maximumWidth: Settings.wallpaperPillTextMaxWidth
                elide: Text.ElideMiddle
                text: root.baseOf(root.selPath).replace(/\.[^.]+$/, "")
                color: Theme.text
                font.family: Theme.font; font.pixelSize: Theme.fontMd; font.weight: Theme.weightSemibold
            }

            Chip {
                label: "All"
                selected: root.folder === ""
                onTapped: root.setFolder("")
            }
            Repeater {
                model: root.folders.length > 1 ? root.folders.slice(0, 4) : []
                delegate: Chip {
                    required property string modelData
                    label: root.baseOf(modelData)
                    selected: root.folder === modelData
                    onTapped: root.setFolder(modelData)
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: root.pics.length > 0
                text: (root.selIndex >= 0 ? (root.selIndex + 1) + " of " : "") + root.pics.length
                color: Theme.faint
                font.family: Theme.font; font.pixelSize: Theme.fontSm
                font.features: ({ "tnum": 1 })
            }
            Chip {
                label: "Monochrome"
                on: Sys.wallpaperMono
                onTapped: Sys.setWallpaperMono(!Sys.wallpaperMono)
            }
            Chip {
                label: "Shuffle"
                onTapped: root.shuffle()
            }
            Chip {
                label: "Cancel"
                onTapped: Sys.wallpaperOpen = false
            }
            Chip {
                label: "Keep"
                strong: true
                onTapped: root.keep()
            }
        }

        ListView {
            id: strip
            Layout.fillWidth: true
            Layout.preferredHeight: root.wpStripHeight
            opacity: root.intro(1)
            transform: Translate { y: root.rise(1) }
            orientation: ListView.Horizontal
            spacing: 0
            clip: true
            model: root.pics
            interactive: false
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: root.wpCellWidth * 6
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (width - root.wpCellWidth) / 2
            preferredHighlightEnd: (width + root.wpCellWidth) / 2
            highlightMoveDuration: root.stripAnimated ? 280 : 0
            highlightMoveVelocity: -1

            WheelHandler {
                onWheel: (e) => {
                    root.wheelAcc += e.angleDelta.y;
                    if (root.wheelAcc <= -120) { root.wheelAcc = 0; root.step(1); }
                    else if (root.wheelAcc >= 120) { root.wheelAcc = 0; root.step(-1); }
                }
            }

            delegate: Item {
                id: cell
                required property string modelData
                readonly property bool picked: modelData === root.selPath
                readonly property bool live: modelData === Sys.wallpaper
                width: root.wpCellWidth
                height: ListView.view.height

                ClippingRectangle {
                    id: frame
                    anchors.centerIn: parent
                    width: root.wpThumbWidth
                    height: root.wpThumbHeight
                    // Capsule thumbs: the strip reads as one row of candy bars.
                    radius: height / 2
                    color: Theme.tile
                    border.width: cell.picked ? 2 : 1
                    border.color: cell.picked ? Theme.text : Theme.line
                    scale: cell.picked ? root.wpPickedScale
                         : cellArea.pressed ? Theme.pressScale
                         : cellArea.containsMouse ? Theme.hoverScale : 1
                    opacity: (cell.picked || cellArea.containsMouse) ? 1.0 : Theme.opacityDim
                    Behavior on scale {
                        Tween {
                            duration: cellArea.pressed ? Theme.durPress : Theme.durBase
                            easing.type: cellArea.pressed ? Theme.easeOut : Theme.easeSnappy
                        }
                    }
                    Behavior on opacity { Tween { duration: Theme.durFast } }

                    Image {
                        id: thumb
                        anchors.fill: parent
                        property bool useOrig: false
                        readonly property int ver: Sys.thumbsVersion
                        onVerChanged: if (useOrig) useOrig = false
                        source: useOrig ? "file://" + cell.modelData : "file://" + Sys.thumbFor(cell.modelData)
                        onStatusChanged: if (status === Image.Error && !useOrig) useOrig = true
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 380
                        layer.enabled: Sys.wallpaperMono
                        layer.effect: MultiEffect { saturation: -1.0 }
                    }

                    // Gloss: bright across the top, a thin bounce at the
                    // bottom, so the capsule looks rounded instead of flat.
                    Rectangle {
                        anchors.fill: parent
                        radius: frame.radius
                        opacity: cell.picked ? 1 : 0.65
                        Behavior on opacity { Tween { duration: Theme.durFast } }
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#38ffffff" }
                            GradientStop { position: 0.42; color: "#00ffffff" }
                            GradientStop { position: 0.88; color: "#00ffffff" }
                            GradientStop { position: 1.0; color: "#1cffffff" }
                        }
                    }

                    Rectangle {
                        visible: cell.live
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.margins: Theme.space8
                        width: curText.implicitWidth + 12
                        height: root.wpBadgeHeight
                        radius: Math.min(width, height) / 2
                        color: Theme.scrim
                        Text {
                            id: curText
                            anchors.centerIn: parent
                            text: "Current"
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontXs; font.weight: Theme.weightMedium
                        }
                    }
                }

                MouseArea {
                    id: cellArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: root.hover(cell.modelData)
                    onExited: if (root.hoverPath === cell.modelData) root.hover("")
                    onClicked: { root.select(cell.modelData); root.keep(); }
                }
            }
        }
    }

    Text {
        visible: root.pics.length === 0
        opacity: root.intro(2)
        transform: Translate { y: root.rise(2) }
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: "No images yet.\nPut wallpapers in ~/Pictures/Wallpapers"
        color: Theme.dim
        font.family: Theme.font; font.pixelSize: Theme.fontMd
    }

    component Chip: Item {
        readonly property int wpChipDefaultHeight: 30
        id: chip
        property string label: ""
        property bool selected: false
        property bool strong: false
        property bool on: false
        signal tapped()
        readonly property bool underlined: selected || strong
        readonly property bool bright: underlined || on || chipArea.containsMouse
        implicitWidth: chipText.implicitWidth + 4
        implicitHeight: wpChipDefaultHeight
        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.bright ? Theme.text : Theme.dim
            font.family: Theme.font; font.pixelSize: Theme.fontSm
            font.weight: chip.strong ? Theme.weightSemibold : Theme.weightMedium
            Behavior on color { TweenColor { duration: Theme.durFast } }
        }
        Rectangle {
            anchors { left: chipText.left; right: chipText.right; top: chipText.bottom; topMargin: Theme.space2 }
            height: Theme.borderThin
            color: Theme.text
            visible: chip.underlined
        }
        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.tapped()
        }
    }
}
