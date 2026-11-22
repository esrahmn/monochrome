import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../shared/components"

Rectangle {
    id: ov

    required property var screenInfo
    property bool live: false
    property string query: ""
    signal activated(string cmd)

    readonly property HyprlandMonitor hmon: Hyprland.monitorFor(screenInfo)
    readonly property var mon: Sys.hyprMonitors.find(m => m.name === screenInfo.name) ?? null

    readonly property int rows: Settings.overviewRows
    readonly property int cols: Settings.overviewColumns
    readonly property int perGroup: rows * cols
    readonly property real baseWsW: monW - res[0] - res[2]
    readonly property real baseWsH: monH - res[1] - res[3]
    readonly property real availableW: Math.max(1, screenInfo.width - Theme.space32 * 2)
    readonly property real availableH: Math.max(1, screenInfo.height - 276)
    readonly property real fitScale: Math.min(
        availableW / Math.max(1, baseWsW * cols + gap * (cols - 1)),
        availableH / Math.max(1, baseWsH * rows + gap * (rows - 1)))
    readonly property real s: Math.min(fitScale, fitScale * Math.max(0.55, Settings.overviewScale / 0.14))
    readonly property int gap: 18

    readonly property var res: mon?.reserved ?? [0, 0, 0, 0]
    readonly property real monW: mon ? ((mon.transform % 2 === 1) ? mon.height : mon.width) / mon.scale : screenInfo.width
    readonly property real monH: mon ? ((mon.transform % 2 === 1) ? mon.width : mon.height) / mon.scale : screenInfo.height
    readonly property real wsW: Math.round((monW - res[0] - res[2]) * s)
    readonly property real wsH: Math.round((monH - res[1] - res[3]) * s)

    readonly property int activeWs: Math.max(1, hmon?.activeWorkspace?.id ?? 1)
    readonly property int group: Math.floor((activeWs - 1) / perGroup)
    readonly property int firstWs: group * perGroup + 1

    property bool dragging: false
    property int dragTarget: -1
    readonly property color edgeSoft: Qt.alpha(Theme.text, 0.4)
    readonly property color edgeStrong: Qt.alpha(Theme.text, 0.65)

    property bool kbActive: false
    property int cursorWs: -1
    property string cursorWin: ""
    readonly property int cur: (cursorWs >= firstWs && cursorWs < firstWs + perGroup) ? cursorWs : activeWs
    readonly property int frameWs: dragging ? dragTarget : ((kbActive && cursorWin === "") ? cur : -1)

    function resetCursor() { kbActive = false; cursorWs = -1; cursorWin = ""; }
    function moveCursor(dx, dy) {
        const i = cur - firstWs;
        const c = Math.max(0, Math.min(cols - 1, (i % cols) + dx));
        const r = Math.max(0, Math.min(rows - 1, Math.floor(i / cols) + dy));
        cursorWs = firstWs + r * cols + c;
        cursorWin = "";
        kbActive = true;
    }
    function cycleWindow(dir) {
        const list = clients.slice().sort((a, b) => a.workspace.id - b.workspace.id);
        const n = list.length;
        if (n === 0) return;
        let i = list.findIndex(c => c.address === cursorWin);
        i = i < 0 ? (dir > 0 ? 0 : n - 1) : (i + dir + n) % n;
        cursorWin = list[i].address;
        cursorWs = list[i].workspace.id;
        kbActive = true;
    }
    function activateCursor() {
        if (cursorWin !== "") ov.activated("hl.dsp.focus({ window = \"address:" + cursorWin + "\" })");
        else ov.activated("hl.dsp.focus({ workspace = " + cur + " })");
    }
    function activateFirstMatch() {
        if (clients.length > 0)
            ov.activated("hl.dsp.focus({ window = \"address:" + clients[0].address + "\" })");
    }
    function closeCursorWindow() {
        if (cursorWin === "") return;
        dispatch("hl.dsp.window.close({ window = \"address:" + cursorWin + "\" })");
        cursorWin = "";
    }
    function handleKey(e) {
        switch (e.key) {
        case Qt.Key_Left:  case Qt.Key_H: moveCursor(-1, 0); return true;
        case Qt.Key_Right: case Qt.Key_L: moveCursor(1, 0); return true;
        case Qt.Key_Up:    case Qt.Key_K: moveCursor(0, -1); return true;
        case Qt.Key_Down:  case Qt.Key_J: moveCursor(0, 1); return true;
        case Qt.Key_Tab:     cycleWindow(1); return true;
        case Qt.Key_Backtab: cycleWindow(-1); return true;
        case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: activateCursor(); return true;
        case Qt.Key_Delete: case Qt.Key_Backspace: case Qt.Key_X: closeCursorWindow(); return true;
        }
        if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9 && e.key - Qt.Key_0 <= perGroup) {
            ov.activated("hl.dsp.focus({ workspace = " + (firstWs + e.key - Qt.Key_0 - 1) + " })");
            return true;
        }
        return false;
    }

    readonly property var clients: {
        const q = ov.query.trim().toLowerCase();
        return Sys.hyprClients.filter(c => {
            if (!c.mapped || !c.workspace || c.workspace.id < firstWs || c.workspace.id >= firstWs + perGroup)
                return false;
            if (q === "") return true;
            return [c.title, c.class, c.initialTitle, c.initialClass]
                .some(value => String(value ?? "").toLowerCase().includes(q));
        });
    }
    readonly property var byAddr: {
        const m = ({});
        for (const c of clients) m[c.address] = c;
        return m;
    }

    function cellPos(ws) {
        const i = ws - firstWs;
        return { x: (i % cols) * (wsW + gap), y: Math.floor(i / cols) * (wsH + gap) };
    }
    function wsAt(px, py) {
        const c = Math.floor(px / (wsW + gap)), r = Math.floor(py / (wsH + gap));
        if (c < 0 || c >= cols || r < 0 || r >= rows) return -1;
        if (px - c * (wsW + gap) > wsW || py - r * (wsH + gap) > wsH) return -1;
        return firstWs + r * cols + c;
    }
    function dispatch(cmd) { Hyprland.dispatch(cmd); }
    function pruneShots() {
        const alive = ({});
        for (const c of Sys.hyprClients) alive[c.address] = true;
        const kept = ({});
        for (const k in Sys.overviewShots) if (alive[k]) kept[k] = Sys.overviewShots[k];
        Sys.overviewShots = kept;
    }

    implicitWidth: grid.width + 24
    implicitHeight: grid.height + 24
    color: Theme.transparent

    MouseArea { anchors.fill: parent }

    Item {
        id: grid
        anchors.centerIn: parent
        width: ov.cols * ov.wsW + (ov.cols - 1) * ov.gap
        height: ov.rows * ov.wsH + (ov.rows - 1) * ov.gap

        Repeater {
            model: ov.perGroup
            delegate: Rectangle {
                id: cell
                required property int index
                readonly property int ws: ov.firstWs + index
                readonly property bool isTarget: ov.dragging && ov.dragTarget === ws
                readonly property bool isCursor: ov.kbActive && ov.cursorWin === "" && ov.cur === ws
                x: (index % ov.cols) * (ov.wsW + ov.gap)
                y: Math.floor(index / ov.cols) * (ov.wsH + ov.gap)
                width: ov.wsW
                height: ov.wsH
                radius: Theme.radiusCard
                color: (isTarget || isCursor) ? Theme.tileHover : (cellArea.containsMouse && !ov.dragging ? Theme.tile : Theme.tile)
                border.width: 1
                border.color: Theme.line
                Behavior on color { TweenColor { duration: Theme.durFast } }

                MouseArea {
                    id: cellArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        ov.activated("hl.dsp.focus({ workspace = " + cell.ws + " })");
                    }
                }
            }
        }

        Repeater {
            model: ScriptModel { values: ov.clients.map(c => c.address) }

            delegate: Item {
                id: w
                required property string modelData
                readonly property var c: ov.byAddr[modelData] ?? null
                readonly property var cmon: Sys.hyprMonitors.find(m => m.id === c?.monitor) ?? ov.mon
                readonly property var cres: cmon?.reserved ?? [0, 0, 0, 0]
                readonly property var cell: ov.cellPos(c?.workspace?.id ?? ov.firstWs)
                readonly property real baseX: cell.x + Math.max(0, ((c?.at[0] ?? 0) - (cmon?.x ?? 0) - cres[0]) * ov.s)
                readonly property real baseY: cell.y + Math.max(0, ((c?.at[1] ?? 0) - (cmon?.y ?? 0) - cres[1]) * ov.s)
                readonly property var toplevel: Hyprland.toplevels.values.find(t => "0x" + t.address === modelData)?.wayland ?? null

                property real dx: 0
                property real dy: 0
                property bool held: false
                property bool moved: false
                readonly property bool sel: ov.kbActive && ov.cursorWin === modelData
                readonly property bool isActive: ("0x" + (Hyprland.activeToplevel?.address ?? "")) === modelData

                readonly property bool wantsPreview: ov.live && Settings.overviewLivePreview && toplevel !== null
                property bool capReset: false
                property int retries: 0
                function restartCapture() {
                    if (capReset) return;
                    capReset = true;
                    Qt.callLater(() => w.capReset = false);
                }
                onWantsPreviewChanged: retries = 0
                readonly property var snap: Sys.overviewShots[modelData] ?? null
                function snapshot() {
                    if (!preview.hasContent || preview.width < 2 || preview.height < 2) return;
                    const addr = modelData;
                    preview.grabToImage(function (result) {
                        const next = Object.assign({}, Sys.overviewShots);
                        next[addr] = result;
                        Sys.overviewShots = next;
                    }, Qt.size(Math.ceil(preview.width * 2), Math.ceil(preview.height * 2)));
                }
                Timer { id: snapDelay; interval: 350; onTriggered: w.snapshot() }
                Timer {
                    interval: 2500
                    repeat: true
                    running: w.wantsPreview && preview.hasContent
                    onTriggered: w.snapshot()
                }
                Timer {
                    interval: Settings.overviewPreviewRetryMs
                    repeat: true
                    running: w.wantsPreview && !preview.hasContent && w.retries < 6
                    onTriggered: { w.retries++; w.restartCapture(); }
                }

                visible: c !== null && c.workspace.id > 0
                x: baseX + dx
                y: baseY + dy
                width: Math.max(10, Math.min((c?.size[0] ?? 0) * ov.s, ov.wsW))
                height: Math.max(10, Math.min((c?.size[1] ?? 0) * ov.s, ov.wsH))
                z: held ? 100 : ((c?.floating ? 3 : 2) + (c?.fullscreen ? 2 : 0))
                scale: held && moved ? 1.04 : 1
                Behavior on x { enabled: !w.held; Tween {} }
                Behavior on y { enabled: !w.held; Tween {} }
                Behavior on scale { Tween { duration: Theme.durFast } }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusControl
                    color: Theme.scrim
                }

                Image {
                    anchors.fill: parent
                    source: w.snap ? w.snap.url : ""
                    cache: false
                    smooth: true
                    opacity: 1 - preview.opacity
                    visible: opacity > 0.01 && source !== ""
                }

                ScreencopyView {
                    id: preview
                    anchors.fill: parent
                    captureSource: (ov.live && Settings.overviewLivePreview && !w.capReset) ? w.toplevel : null
                    live: true
                    opacity: hasContent ? 1 : 0
                    Behavior on opacity { Tween { duration: Theme.durFast } }
                    onHasContentChanged: {
                        if (hasContent) snapDelay.restart();
                        else if (w.wantsPreview) w.restartCapture();
                    }
                    onStopped: {
                        if (w.wantsPreview && w.retries < 6) { w.retries++; w.restartCapture(); }
                    }
                }

                Text {
                    visible: !preview.hasContent && w.snap === null && (!Settings.overviewLivePreview || w.retries >= 2)
                    anchors { fill: parent; margins: Theme.space8 }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: w.c?.title || w.c?.class || ""
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: Theme.fontXs
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusControl
                    color: (w.sel || (area.containsMouse && !ov.kbActive)) ? Theme.tile : Theme.transparent
                    border.width: (w.sel || w.held) ? 2 : (w.isActive ? 1 : 0)
                    border.color: (w.sel || w.held) ? ov.edgeStrong : ov.edgeSoft
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    cursorShape: w.held && w.moved ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    property point start

                    onPressed: (m) => {
                        if (m.button !== Qt.LeftButton) return;
                        start = mapToItem(grid, m.x, m.y);
                        w.held = true;
                        w.moved = false;
                    }
                    onPositionChanged: (m) => {
                        if (!w.held) { if (ov.kbActive) ov.kbActive = false; return; }
                        const p = mapToItem(grid, m.x, m.y);
                        w.dx = p.x - start.x;
                        w.dy = p.y - start.y;
                        if (!w.moved && Math.hypot(w.dx, w.dy) > 6) { w.moved = true; ov.dragging = true; }
                        if (w.moved) ov.dragTarget = ov.wsAt(p.x, p.y);
                    }
                    onReleased: (m) => {
                        if (m.button === Qt.MiddleButton) {
                            ov.dispatch("hl.dsp.window.close({ window = \"address:" + w.modelData + "\" })");
                            return;
                        }
                        if (!w.held) return;
                        const target = ov.dragTarget;
                        const wasMoved = w.moved;
                        w.held = false;
                        w.moved = false;
                        ov.dragging = false;
                        ov.dragTarget = -1;
                        w.dx = 0;
                        w.dy = 0;
                        if (wasMoved) {
                            if (target > 0 && target !== w.c.workspace.id)
                                ov.dispatch("hl.dsp.window.move({ workspace = " + target + ", follow = false, window = \"address:" + w.modelData + "\" })");
                        } else {
                            ov.activated("hl.dsp.focus({ window = \"address:" + w.modelData + "\" })");
                        }
                    }
                }
            }
        }

        Repeater {
            model: ov.perGroup
            delegate: Rectangle {
                required property int index
                readonly property int ws: ov.firstWs + index
                readonly property var p: ov.cellPos(ws)
                x: p.x + Theme.space8
                y: p.y + Theme.space8
                z: 40
                width: 92
                height: 26
                radius: Theme.radiusControl
                color: Qt.rgba(0, 0, 0, 0.58)
                border.width: 1
                border.color: Theme.line
                Text {
                    anchors.centerIn: parent
                    text: "Desktop " + parent.ws
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontXs
                }
            }
        }

        Rectangle {
            readonly property var p: ov.cellPos(ov.activeWs)
            visible: ov.activeWs >= ov.firstWs && ov.activeWs < ov.firstWs + ov.perGroup && ov.frameWs !== ov.activeWs
            x: p.x - 1; y: p.y - 1
            width: ov.wsW + 2; height: ov.wsH + 2
            z: 50
            radius: Theme.radiusCard
            color: Theme.transparent
            border.width: Theme.borderStrong
            border.color: ov.edgeSoft
            Behavior on x { Tween {} }
            Behavior on y { Tween {} }
        }

        Rectangle {
            readonly property var p: ov.cellPos(ov.frameWs)
            visible: ov.frameWs >= ov.firstWs && ov.frameWs < ov.firstWs + ov.perGroup
            x: p.x - 1; y: p.y - 1
            width: ov.wsW + 2; height: ov.wsH + 2
            z: 50
            radius: Theme.radiusCard
            color: Theme.transparent
            border.width: Theme.borderStrong
            border.color: ov.edgeStrong
        }
    }
}
