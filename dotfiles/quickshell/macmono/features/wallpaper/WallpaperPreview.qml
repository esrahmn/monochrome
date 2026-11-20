import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool shown: Sys.wallpaperOpen && Sys.wallpaperScreen === modelData.name
            Reveal {
                id: reveal
                open: win.shown
                onSettled: (isOpen) => {
                    if (!isOpen) {
                        swapAnim.stop();
                        win.swapT = 1;
                    }
                }
            }
            readonly property real ui: reveal.progress

            property bool frontA: true
            property real swapT: 1
            property int swapDir: 1
            property string shownPath: ""
            onFrontAChanged: swapAnim.restart()
            NumberAnimation {
                id: swapAnim
                target: win; property: "swapT"
                from: 0; to: 1
                duration: Theme.wallpaperFadeMs
                easing.type: Easing.Linear
            }

            function urlOf(p) { return p !== "" ? "file://" + p : ""; }

            function loadPreview() {
                const path = Sys.wallpaperPreview;
                if (path === "" || path === shownPath) return;
                const list = Sys.wallpapers;
                const a = list.indexOf(shownPath), b = list.indexOf(path);
                swapDir = b >= a ? 1 : -1;
                shownPath = path;
                const url = urlOf(path);
                const front = frontA ? imgA : imgB;
                const back = frontA ? imgB : imgA;
                if (String(front.source) === url) return;
                if (String(back.source) === url && back.status === Image.Ready) { frontA = !frontA; return; }
                back.source = url;
            }

            Connections {
                target: Sys
                function onWallpaperPreviewChanged() { win.loadPreview(); }
            }

            onShownChanged: {
                if (!shown) return;
                shownPath = Sys.wallpaperPreview !== "" ? Sys.wallpaperPreview : Sys.wallpaper;
                frontA = true;
                imgB.source = "";
                imgA.source = urlOf(shownPath);
                swapAnim.stop();
                swapT = 1;
            }

            visible: shown || reveal.progress > 0.001
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "macmono:wallpaper-picker"
            WlrLayershell.layer: WlrLayer.Top
            mask: Region { item: noInput }
            Item { id: noInput; width: 0; height: 0 }

            Item {
                id: preview
                anchors.fill: parent
                opacity: win.ui
                clip: true
                layer.enabled: Sys.wallpaperMono
                layer.effect: MultiEffect { saturation: -1.0 }

                WallMotion { id: swapMotion; t: win.swapT; dir: win.swapDir; span: win.width }

                Rectangle { anchors.fill: parent; color: Theme.scrim }
                Image {
                    id: imgA
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: win.width
                    z: win.frontA ? 2 : 1
                    opacity: win.frontA ? swapMotion.inOpacity : 1
                    scale: win.frontA ? swapMotion.inScale : swapMotion.outScale
                    transform: Translate { x: win.frontA ? swapMotion.inX : swapMotion.outX }
                    onStatusChanged: if (status === Image.Ready && !win.frontA) win.frontA = true
                }
                Image {
                    id: imgB
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: win.width
                    z: win.frontA ? 1 : 2
                    opacity: win.frontA ? 1 : swapMotion.inOpacity
                    scale: win.frontA ? swapMotion.outScale : swapMotion.inScale
                    transform: Translate { x: win.frontA ? swapMotion.outX : swapMotion.inX }
                    onStatusChanged: if (status === Image.Ready && win.frontA) win.frontA = false
                }

                Rectangle { anchors.fill: parent; z: 1.5; color: "black"; opacity: win.swapT < 1 ? swapMotion.dip : 0 }
            }
        }
    }
}
