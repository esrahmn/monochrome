import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool enabled: false
    property int refreshMin: 30
    property int timeoutSec: 25

    property bool ok: false
    property bool locating: false
    property string error: ""
    property string name: ""
    property real lat: 0
    property real lon: 0

    property int failures: 0
    property real pendingLat: 0
    property real pendingLon: 0
    property string pendingKey: ""
    property string namedKey: ""

    readonly property string script: Quickshell.shellDir + "/scripts/session/locate.py"
    readonly property string reverseUrl: "https://nominatim.openstreetmap.org/reverse"

    function locate() {
        if (!enabled || locateProc.running || nameProc.running) return;
        locating = true;
        error = "";
        locateProc.running = true;
    }

    function describeError(code, message) {
        if (code === "missing") return "GeoClue is not installed or not running. Install the geoclue package.";
        if (code === "denied") return "GeoClue does not allow macmono yet. Add the [macmono] entry to /etc/geoclue/conf.d.";
        if (code === "nofix") return "No location yet. Check your internet connection.";
        if (code === "nogi") return "python-gobject is missing.";
        return message ? String(message).slice(0, 160) : "Could not detect your location.";
    }

    function fail(message) {
        locating = false;
        error = message;
        failures++;
        if (!ok) retry.restart();
    }

    function publish(label) {
        lat = pendingLat;
        lon = pendingLon;
        name = label;
        ok = true;
        locating = false;
        error = "";
        failures = 0;
    }

    onEnabledChanged: {
        if (enabled) {
            failures = 0;
            startDelay.restart();
        } else {
            startDelay.stop();
            retry.stop();
            locating = false;
            ok = false;
            error = "";
        }
    }
    Component.onCompleted: if (enabled) startDelay.restart()

    Timer { id: startDelay; interval: 3000; onTriggered: root.locate() }
    Timer { id: retry; interval: root.failures < 5 ? 20000 : 300000; onTriggered: root.locate() }
    Timer {
        interval: root.refreshMin * 60000
        running: root.enabled && root.ok
        repeat: true
        onTriggered: root.locate()
    }

    Process {
        id: locateProc
        command: ["python3", root.script, String(root.timeoutSec)]
        stdout: StdioCollector {
            onStreamFinished: {
                let r = null;
                try { r = JSON.parse(text); } catch (e) {}
                if (!r) { root.fail("The location helper did not answer."); return; }
                if (!r.ok) { root.fail(root.describeError(r.code, r.error)); return; }

                root.pendingLat = r.lat;
                root.pendingLon = r.lon;
                root.pendingKey = r.lat.toFixed(2) + "," + r.lon.toFixed(2);
                if (root.pendingKey === root.namedKey && root.name !== "") { root.publish(root.name); return; }

                nameProc.command = ["curl", "-sS", "--max-time", "8", "--get", "-A", "macmono-shell",
                    "--data-urlencode", "format=jsonv2",
                    "--data-urlencode", "zoom=10",
                    "--data-urlencode", "addressdetails=1",
                    "--data-urlencode", "accept-language=en",
                    "--data-urlencode", "lat=" + r.lat,
                    "--data-urlencode", "lon=" + r.lon,
                    root.reverseUrl];
                nameProc.running = true;
            }
        }
    }

    Process {
        id: nameProc
        stdout: StdioCollector {
            onStreamFinished: {
                let label = "";
                try {
                    const a = JSON.parse(text).address || {};
                    const place = a.city || a.town || a.village || a.municipality || a.county || a.state_district || "";
                    const parts = [];
                    for (const p of [place, a.state, a.country])
                        if (p && parts.indexOf(p) < 0) parts.push(p);
                    label = parts.join(", ");
                } catch (e) {}
                root.namedKey = label ? root.pendingKey : "";
                root.publish(label || "Current location");
            }
        }
    }
}
