import QtQuick
import QtQuick.Effects
import "../../core"
import "../../shared/components"

Image {
    id: root

    property string wallpaperPath: ""
    property real reveal: 0
    property var partner: null
    property bool outgoing: false
    property int dir: 1
    property real pixelWidth: 0
    property real pixelHeight: 0

    signal loaded(string path)
    signal failed(string path)

    WallMotion {
        id: motion
        t: root.outgoing ? (root.partner ? root.partner.reveal : 0) : root.reveal
        dir: root.dir
        span: root.width
    }

    anchors.fill: parent
    source: wallpaperPath !== "" ? "file://" + wallpaperPath : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: pixelWidth
    sourceSize.height: pixelHeight
    opacity: root.outgoing ? 1 : motion.inOpacity
    scale: root.outgoing ? motion.outScale : motion.inScale
    transform: Translate { x: root.outgoing ? motion.outX : motion.inX }
    layer.enabled: Sys.wallpaperMono
    layer.effect: MultiEffect { saturation: -1.0 }

    onStatusChanged: {
        if (status === Image.Ready) root.loaded(root.wallpaperPath);
        else if (status === Image.Error) root.failed(root.wallpaperPath);
    }
}
