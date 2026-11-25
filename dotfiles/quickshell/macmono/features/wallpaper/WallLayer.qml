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

    // Mask texture for the capsule wipe, owned by the layer host.
    property Item wipeMask: null

    signal loaded(string path)
    signal failed(string path)

    readonly property bool wiping: root.wipeMask !== null && !root.outgoing && root.reveal < 1

    WallMotion {
        id: motion
        t: root.outgoing ? (root.partner ? root.partner.reveal : 0) : root.reveal
        dir: root.dir
        span: root.width
        vspan: root.height
    }

    anchors.fill: parent
    source: wallpaperPath !== "" ? "file://" + wallpaperPath : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: pixelWidth
    sourceSize.height: pixelHeight
    // An incoming layer only exists to be wiped in, so keep it hidden until
    // the mask has something to reveal.
    opacity: root.outgoing || root.reveal > 0 ? 1 : 0
    scale: root.outgoing ? motion.outScale : motion.inScale
    transform: Translate { x: root.outgoing ? motion.outX : motion.inX }
    layer.enabled: Sys.wallpaperMono || root.wiping
    layer.effect: MultiEffect {
        saturation: Sys.wallpaperMono ? -1.0 : 0.0
        maskEnabled: root.wiping
        maskSource: root.wipeMask
    }

    onStatusChanged: {
        if (status === Image.Ready) root.loaded(root.wallpaperPath);
        else if (status === Image.Error) root.failed(root.wallpaperPath);
    }
}
