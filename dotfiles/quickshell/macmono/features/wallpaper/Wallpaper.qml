import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../shared/components"

// The desktop wallpaper itself (crossfades between images). Picking one happens in the island
// (WallpaperPanel); showing the candidate over windows is WallpaperPreview.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bg
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.scrim
            WlrLayershell.namespace: "macmono:wallpaper"
            WlrLayershell.layer: WlrLayer.Background

            Item {
                id: wall
                anchors.fill: parent
                clip: true

                property bool frontA: true
                property bool fading: false
                property string frontPath: ""
                property int dir: 1
                property var incoming: null
                readonly property string wanted: Sys.wallpaper
                readonly property real dpr: bg.screen ? bg.screen.devicePixelRatio : 1

                function front() { return wall.frontA ? layerA : layerB; }
                function back() { return wall.frontA ? layerB : layerA; }

                // Completes a running crossfade at once and frees the old image.
                function finish() {
                    if (!wall.fading) return;
                    fade.stop();
                    wall.fading = false;
                    const old = wall.front();
                    const incoming = wall.back();
                    incoming.reveal = 1;
                    old.outgoing = false;
                    old.reveal = 0;
                    old.wallpaperPath = "";
                    wall.incoming = null;
                    wall.frontPath = incoming.wallpaperPath;
                    wall.frontA = !wall.frontA;
                }

                function present(layer) {
                    Sys.markWallpaperReady(layer.wallpaperPath, bg.modelData.name);
                    wall.front().z = 1;
                    layer.z = 2;
                    wall.front().outgoing = true;
                    layer.outgoing = false;
                    wall.incoming = layer;
                    wall.fading = true;
                    // The preview covers the screen while the picker is open, so swap without a fade.
                    if (Sys.wallpaperOpen) {
                        layer.reveal = 1;
                        wall.finish();
                        return;
                    }
                    fade.target = layer;
                    fade.restart();
                }

                function load(path) {
                    wall.finish();
                    if (path === wall.frontPath) {
                        wall.back().wallpaperPath = "";
                        return;
                    }
                    if (path === "") {
                        wall.front().wallpaperPath = "";
                        wall.front().reveal = 0;
                        wall.frontPath = "";
                        return;
                    }
                    const list = Sys.wallpapers;
                    const a = list.indexOf(wall.frontPath), b = list.indexOf(path);
                    if (a >= 0 && b >= 0 && a !== b) {
                        let fwd = b > a;
                        if (Math.abs(b - a) > list.length / 2) fwd = !fwd;
                        wall.dir = fwd ? 1 : -1;
                    }
                    wall.back().wallpaperPath = path;
                }

                function layerLoaded(layer, path) {
                    if (wall.fading || layer !== wall.back() || path !== wall.wanted) return;
                    wall.present(layer);
                }

                onWantedChanged: wall.load(wall.wanted)
                Component.onCompleted: wall.load(wall.wanted)

                NumberAnimation {
                    id: fade
                    property: "reveal"
                    from: 0
                    to: 1
                    duration: Theme.wallpaperFadeMs
                    easing.type: Easing.Linear   // class C: curve shaped in WallMotion
                    onFinished: wall.finish()
                }

                // The old image darkens as the new one slides over it (z 1.5: between the two layers).
                WallMotion { id: dimMotion; t: wall.incoming ? wall.incoming.reveal : 0; dir: wall.dir; span: bg.width }
                Rectangle {
                    anchors.fill: parent
                    z: 1.5
                    color: "black"
                    opacity: dimMotion.dip
                }

                WallLayer {
                    id: layerA
                    partner: layerB
                    dir: wall.dir
                    pixelWidth: Math.round(bg.width * wall.dpr)
                    pixelHeight: Math.round(bg.height * wall.dpr)
                    onLoaded: (path) => wall.layerLoaded(layerA, path)
                    onFailed: (path) => Sys.markWallpaperLoadError(path)
                }
                WallLayer {
                    id: layerB
                    partner: layerA
                    dir: wall.dir
                    pixelWidth: Math.round(bg.width * wall.dpr)
                    pixelHeight: Math.round(bg.height * wall.dpr)
                    onLoaded: (path) => wall.layerLoaded(layerB, path)
                    onFailed: (path) => Sys.markWallpaperLoadError(path)
                }
            }
        }
    }
}
