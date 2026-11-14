import QtQuick
pragma Singleton

QtObject {
    id: root

    property var entries: ({
    })
    readonly property int maxEntries: 40

    function get(trackKey) {
        return entries[trackKey] || null;
    }

    function put(trackKey, lines, status, retryAvailable) {
        const next = {
        };
        for (const k in entries) next[k] = entries[k]
        next[trackKey] = {
            "lines": lines.slice(),
            "status": status,
            "retryAvailable": retryAvailable === true,
            "savedAt": Date.now()
        };
        const keys = Object.keys(next);
        if (keys.length > maxEntries) {
            keys.sort((a, b) => {
                return next[a].savedAt - next[b].savedAt;
            });
            const drop = keys.length - maxEntries;
            for (let i = 0; i < drop; i++) delete next[keys[i]]
        }
        entries = next;
    }

    function remove(trackKey) {
        if (!(trackKey in entries))
            return ;

        const next = {
        };
        for (const k in entries) if (k !== trackKey) {
            next[k] = entries[k];
        }
        entries = next;
    }

}
