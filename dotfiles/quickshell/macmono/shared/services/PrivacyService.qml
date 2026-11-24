import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Scope {
    id: root

    property int activePollMs: 2000
    property bool cameraPossible: false

    readonly property bool micInUse: Pipewire.nodes.values.some(n => {
        if (!n.isStream || n.isSink || !n.audio) return false;
        const app = String(n.properties?.["application.name"] ?? n.properties?.["node.name"] ?? n.name ?? "").toLowerCase();
        return !/easyeffects|pavucontrol|cava|quickshell|pipewire|wireplumber/.test(app);
    })

    readonly property bool screencast: Pipewire.nodes.values.some(n => {
        const p = n.properties ?? {};
        const mc = String(p["media.class"] ?? "");
        const who = (String(n.name ?? "") + " " + String(p["application.name"] ?? "") + " " + String(p["node.name"] ?? "")).toLowerCase();
        return mc === "Video/Source" && /xdp|portal|screencast/.test(who);
    })

    // Camera devices as PipeWire sees them. Using these paths lets us call
    // fuser directly instead of expanding /dev/video* in a shell every poll:
    // apps that grab the device straight through v4l2 (Chrome, Zoom) never
    // show up as PipeWire nodes, so the device check still has to happen.
    readonly property var cameraDevices: Pipewire.nodes.values
        .map(n => n.properties?.["api.v4l2.path"])
        .filter(p => typeof p === "string" && p !== "")

    property bool camInUse: false
    property bool recordingProc: false

    Process {
        id: cameraProbe
        command: ["fuser", "-s"].concat(root.cameraDevices)
        onExited: (exitCode, exitStatus) => root.camInUse = exitCode === 0
    }

    Timer {
        interval: root.activePollMs
        running: root.cameraPossible && root.cameraDevices.length > 0
        repeat: true
        onTriggered: if (!cameraProbe.running) cameraProbe.running = true
    }

    Process {
        id: recorderProbe
        command: ["pidof", "wf-recorder", "gpu-screen-recorder", "wl-screenrec"]
        onExited: (exitCode, exitStatus) => root.recordingProc = exitCode === 0
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!recorderProbe.running) recorderProbe.running = true
    }

    Component.onCompleted: {
        if (root.cameraPossible) cameraProbe.running = true;
        recorderProbe.running = true;
    }
}
