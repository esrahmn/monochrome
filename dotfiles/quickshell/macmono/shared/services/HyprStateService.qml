import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    property string layoutCode: ""
    property int layoutCount: 1
    property bool fullscreen: false
    signal configReloaded()

    readonly property string layoutScript: Quickshell.shellDir + "/scripts/session/kb-layout.sh"
    readonly property int debounceMs: 80
    readonly property var fullscreenEvents: [
        "workspacev2", "focusedmonv2", "activewindowv2",
        "openwindow", "closewindow", "movewindowv2"
    ]

    property var codeCache: ({})
    property string pendingKey: ""
    property bool layoutPending: false
    property bool fullscreenPending: false

    Component.onCompleted: {
        refreshLayout();
        refreshFullscreen();
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const name = event.name;
            if (name === "activelayout") {
                layoutDebounce.restart();
            } else if (name === "fullscreen") {
                root.fullscreen = String(event.data).trim() === "1";
                fsDebounce.restart();
            } else if (name === "configreloaded") {
                layoutDebounce.restart();
                fsDebounce.restart();
                root.configReloaded();
            } else if (root.fullscreenEvents.indexOf(name) !== -1) {
                fsDebounce.restart();
            }
        }
    }

    Timer { id: layoutDebounce; interval: root.debounceMs; onTriggered: root.refreshLayout() }
    Timer { id: fsDebounce; interval: root.debounceMs; onTriggered: root.refreshFullscreen() }

    function refreshLayout() {
        if (devProc.running || codeProc.running) { layoutPending = true; return; }
        devProc.running = true;
    }
    function layoutIdle() {
        if (layoutPending && !devProc.running && !codeProc.running) {
            layoutPending = false;
            layoutDebounce.restart();
        }
    }
    function handleDevices(text) {
        let main = null;
        try {
            const kbs = JSON.parse(text).keyboards ?? [];
            main = kbs.find(k => k.main) ?? kbs[0] ?? null;
        } catch (e) { main = null; }
        if (!main) return;

        const layouts = String(main.layout ?? "");
        const variants = String(main.variant ?? "");
        const active = String(main.active_keymap ?? "");
        layoutCount = Math.max(1, layouts.split(",").filter(s => s.trim() !== "").length);

        const key = active + "|" + layouts + "|" + variants;
        if (codeCache[key] !== undefined) { layoutCode = codeCache[key]; return; }
        pendingKey = key;
        codeProc.command = ["bash", layoutScript, active, layouts, variants];
        codeProc.running = true;
    }

    Process {
        id: devProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector { onStreamFinished: root.handleDevices(text) }
        onExited: root.layoutIdle()
    }
    Process {
        id: codeProc
        stdout: StdioCollector {
            onStreamFinished: {
                const code = text.trim();
                if (code === "") return;
                root.codeCache[root.pendingKey] = code;
                root.layoutCode = code;
            }
        }
        onExited: root.layoutIdle()
    }

    function refreshFullscreen() {
        if (fsProc.running) { fullscreenPending = true; return; }
        fsProc.running = true;
    }
    Process {
        id: fsProc
        command: ["hyprctl", "-j", "activeworkspace"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const w = JSON.parse(text);
                    if (typeof w.hasfullscreen === "boolean") root.fullscreen = w.hasfullscreen;
                } catch (e) {}
            }
        }
        onExited: if (root.fullscreenPending) { root.fullscreenPending = false; fsDebounce.restart(); }
    }
}
