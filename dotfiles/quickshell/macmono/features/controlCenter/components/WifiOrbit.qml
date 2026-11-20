import QtQuick
import "../../../core"
import "../../../shared/components"

Item {
    id: root

    readonly property int orbitCenterSize: 64
    readonly property var orbitRadii: [60, 100, 140]
    readonly property var orbitSpin: [1, -1, 1]
    readonly property int orbitDot: 12
    readonly property int orbitLabelWidth: 72
    readonly property int orbitMaxNodes: 10
    readonly property int orbitEdge: 24
    readonly property int orbitCaptionHeight: 28
    readonly property int orbitLabelRoom: 20
    readonly property real orbitHalf: orbitRadii[2] + orbitEdge
    readonly property real orbitIntroDelay: 0.12
    readonly property real orbitMinOpacity: 0.55
    readonly property real orbitHoverScale: 1.3
    readonly property int orbitStrong: 60
    readonly property int orbitMedium: 35

    readonly property int pwCardWidth: 340
    readonly property int pwFieldHeight: 32
    readonly property int pwShowWidth: 28
    readonly property int pwShowHeight: 24
    readonly property int pwJoinWidth: 72
    readonly property int pwMinLength: 8

    readonly property real cx: width / 2
    readonly property real cy: orbitCaptionHeight + orbitHalf
    readonly property real sceneHeight: orbitCaptionHeight + 2 * orbitHalf + orbitLabelRoom
    readonly property bool connecting: Sys.wifiConnecting !== ""

    property string pwFor: ""
    readonly property bool typing: pwFor !== ""
    property bool hovering: false
    property real spin: 0
    property real ping: 0

    implicitHeight: sceneHeight + Theme.listFooterHeight

    onVisibleChanged: if (!visible) { pwFor = ""; hovering = false; }
    onNodesChanged: hovering = false

    function pick(e) {
        if (e.secure && !e.known) {
            pwFor = e.ssid;
            pw.text = "";
            pw.forceActiveFocus();
            return;
        }
        pwFor = "";
        Sys.connectWifi(e.ssid, "");
    }
    function join() {
        if (pw.text.length >= pwMinLength) {
            Sys.connectWifi(pwFor, pw.text);
            pwFor = "";
        }
    }

    Connections {
        target: Sys
        function onWifiErrorChanged() {
            if (Sys.wifiError !== "" && Sys.wifiError !== Sys.wifiName) {
                root.pwFor = Sys.wifiError;
                pw.text = "";
                pw.forceActiveFocus();
            }
        }
    }

    Reveal { id: rv; open: root.visible }

    NumberAnimation on spin {
        from: 0; to: 2 * Math.PI
        duration: Theme.durOrbit
        loops: Animation.Infinite
        running: root.visible
        paused: root.hovering || root.typing
    }
    NumberAnimation on ping {
        from: 0; to: 1
        duration: Theme.durPulse * 3
        loops: Animation.Infinite
        running: root.visible && root.connecting
    }

    readonly property var nodes: {
        const active = Sys.wifiName;
        const rest = Sys.wifiList
            .filter(e => e.ssid !== active)
            .sort((a, b) => b.signal - a.signal)
            .slice(0, root.orbitMaxNodes);
        const rings = [[], [], []];
        for (const e of rest)
            rings[e.signal >= root.orbitStrong ? 0 : (e.signal >= root.orbitMedium ? 1 : 2)].push(e);
        const out = [];
        for (let r = 0; r < 3; r++) {
            rings[r].sort((a, b) => a.ssid < b.ssid ? -1 : 1);
            const n = rings[r].length;
            for (let i = 0; i < n; i++)
                out.push({ e: rings[r][i], ring: r, angle: 2 * Math.PI * i / n + r * 0.9 - Math.PI / 2 });
        }
        return out;
    }

    Text {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.orbitCaptionHeight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        text: !Sys.wifiOn ? "Wi-Fi is off"
            : root.connecting ? "Connecting to " + Sys.wifiConnecting + "…"
            : (Sys.wifiError !== "" && Sys.wifiError !== Sys.wifiName) ? "Couldn't connect to " + Sys.wifiError + ". Check the password."
            : Sys.wifiName !== "" ? "Connected to " + Sys.wifiName
            : Sys.wifiList.length === 0 ? "Searching for networks…"
            : "Not connected"
        color: Theme.dim
        font.family: Theme.font; font.pixelSize: Theme.fontSm
    }

    Repeater {
        model: root.orbitRadii
        delegate: Rectangle {
            id: ring
            required property real modelData
            required property int index
            readonly property real from: index * 0.08
            width: 2 * modelData; height: 2 * modelData
            radius: modelData
            x: root.cx - modelData
            y: root.cy - modelData
            scale: 0.8 + 0.2 * rv.spanTravel(from, from + 0.45)
            opacity: rv.span(from, from + 0.45)
            color: Theme.transparent
            border.width: Theme.borderThin
            border.color: Theme.line
        }
    }

    Repeater {
        model: root.nodes
        delegate: Item {
            id: spoke
            required property var modelData
            required property int index
            readonly property real from: root.orbitIntroDelay + Math.min(index, Theme.staggerMaxRows) * Theme.staggerStep
            readonly property real radial: root.orbitRadii[modelData.ring]
                * (0.35 + 0.65 * rv.spanTravel(from, from + Theme.staggerSpan))
            x: root.cx; y: root.cy
            width: 0; height: 0
            rotation: (modelData.angle + root.spin * root.orbitSpin[modelData.ring]) * 180 / Math.PI
            opacity: rv.span(from, from + Theme.staggerSpan)

            Rectangle {
                x: root.orbitCenterSize / 2 + Theme.space4
                y: -height / 2
                width: Math.max(0, spoke.radial - root.orbitCenterSize / 2 - Theme.space4 - root.orbitDot)
                height: Theme.borderThin
                color: Theme.line
            }
        }
    }

    Repeater {
        model: root.nodes
        delegate: Item {
            id: node
            required property var modelData
            required property int index
            readonly property real from: root.orbitIntroDelay + Math.min(index, Theme.staggerMaxRows) * Theme.staggerStep
            readonly property real radial: root.orbitRadii[modelData.ring]
                * (0.35 + 0.65 * rv.spanTravel(from, from + Theme.staggerSpan))
            readonly property real ang: modelData.angle + root.spin * root.orbitSpin[modelData.ring]
            width: root.orbitLabelWidth
            height: root.orbitDot + Theme.space4 + Theme.fontSm + Theme.space4
            x: root.cx + radial * Math.cos(ang) - width / 2
            y: root.cy + radial * Math.sin(ang) - root.orbitDot / 2
            opacity: rv.span(from, from + Theme.staggerSpan)
                * (area.containsMouse ? 1
                    : root.orbitMinOpacity + (1 - root.orbitMinOpacity) * Math.min(100, modelData.e.signal) / 100)

            Rectangle {
                id: dot
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.orbitDot; height: root.orbitDot
                radius: width / 2
                scale: area.containsMouse ? root.orbitHoverScale : 1
                Behavior on scale { Tween { duration: Theme.durFast } }
                color: node.modelData.e.known ? Theme.text : Theme.transparent
                border.width: Theme.borderThin
                border.color: Theme.text
            }
            Glyph {
                visible: node.modelData.e.secure && !node.modelData.e.known
                anchors { left: dot.right; leftMargin: Theme.space4; verticalCenter: dot.verticalCenter }
                width: root.orbitDot; height: root.orbitDot
                name: "lock"
                color: Theme.dim
            }
            Text {
                anchors { top: dot.bottom; topMargin: Theme.space4; horizontalCenter: parent.horizontalCenter }
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: node.modelData.e.ssid
                color: Theme.text
                font.family: Theme.font; font.pixelSize: Theme.fontSm
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.connecting
                onContainsMouseChanged: root.hovering = containsMouse
                onClicked: root.pick(node.modelData.e)
            }
        }
    }

    Rectangle {
        readonly property real d: root.orbitCenterSize + root.ping * (2 * root.orbitRadii[0] - root.orbitCenterSize)
        visible: root.connecting
        width: d; height: d
        radius: d / 2
        x: root.cx - d / 2
        y: root.cy - d / 2
        color: Theme.transparent
        border.width: Theme.borderThin
        border.color: Theme.text
        opacity: (1 - root.ping) * 0.5
    }

    Rectangle {
        width: root.orbitCenterSize; height: root.orbitCenterSize
        radius: width / 2
        x: root.cx - width / 2
        y: root.cy - height / 2
        scale: 0.6 + 0.4 * rv.spanTravel(0, 0.45)
        opacity: rv.span(0, 0.3)
        color: Sys.wifiName !== "" ? Theme.tileHover : Theme.tile
        border.width: Theme.borderThin
        border.color: Theme.line
        Glyph {
            anchors.centerIn: parent
            width: Theme.iconXl; height: Theme.iconXl
            name: "wifi"
            color: Sys.wifiOn ? Theme.text : Theme.faint
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusCard
        color: Theme.scrim
        opacity: root.typing ? 1 : 0
        visible: root.typing || opacity > 0.01
        Behavior on opacity { Tween {} }

        MouseArea {
            anchors.fill: parent
            enabled: root.typing
            onClicked: root.pwFor = ""
        }

        Rectangle {
            width: root.pwCardWidth
            height: pwCol.implicitHeight + 2 * Theme.space16
            x: root.cx - width / 2
            y: root.cy - height / 2
            radius: Theme.radiusCard
            color: Theme.charcoal
            border.width: Theme.borderThin; border.color: Theme.line
            scale: root.typing ? 1 : Theme.pressScale
            Behavior on scale { Tween {} }

            MouseArea { anchors.fill: parent }

            Column {
                id: pwCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space16 }
                spacing: Theme.space12

                Column {
                    width: parent.width
                    spacing: Theme.space2
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: "Join " + root.pwFor
                        color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontMd; font.weight: Theme.weightSemibold
                    }
                    Text {
                        width: parent.width
                        text: pw.text.length > 0 && pw.text.length < root.pwMinLength
                            ? "Use at least " + root.pwMinLength + " characters"
                            : "Enter the network password"
                        color: Theme.dim
                        font.family: Theme.font; font.pixelSize: Theme.fontXs
                    }
                }

                Rectangle {
                    width: parent.width
                    height: root.pwFieldHeight
                    radius: height / 2
                    color: Theme.scrim
                    border.width: Theme.borderThin
                    border.color: pw.activeFocus ? Theme.lineFocus : Theme.line

                    TextInput {
                        id: pw
                        anchors { fill: parent; leftMargin: Theme.space16; rightMargin: root.pwShowWidth + Theme.space12 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: showPw.checked ? TextInput.Normal : TextInput.Password
                        color: Theme.text
                        selectionColor: Theme.tileHover
                        font.family: Theme.font; font.pixelSize: Theme.fontSm
                        clip: true
                        Keys.onReturnPressed: root.join()
                        Keys.onEnterPressed: root.join()
                        Keys.onEscapePressed: root.pwFor = ""
                        Text {
                            visible: pw.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Password"
                            color: Theme.faint
                            font: pw.font
                        }
                    }
                    MouseArea {
                        id: showPw
                        property bool checked: false
                        anchors { right: parent.right; rightMargin: Theme.space8; verticalCenter: parent.verticalCenter }
                        width: root.pwShowWidth; height: root.pwShowHeight
                        onClicked: checked = !checked
                        Text {
                            anchors.centerIn: parent
                            text: showPw.checked ? "Hide" : "Show"
                            color: Theme.dim
                            font.family: Theme.font; font.pixelSize: Theme.fontXs
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: root.pwFieldHeight

                    Row {
                        anchors.right: parent.right
                        spacing: Theme.space8

                        MouseArea {
                            id: cancelBtn
                            width: cancelText.implicitWidth + 2 * Theme.space16
                            height: root.pwFieldHeight
                            hoverEnabled: true
                            onClicked: root.pwFor = ""
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: cancelBtn.containsMouse ? Theme.tile : Theme.transparent
                                Behavior on color { TweenColor { duration: Theme.durFast } }
                            }
                            Text {
                                id: cancelText
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: cancelBtn.containsMouse ? Theme.text : Theme.dim
                                font.family: Theme.font; font.pixelSize: Theme.fontSm
                            }
                        }
                        MouseArea {
                            id: joinBtn
                            width: root.pwJoinWidth
                            height: root.pwFieldHeight
                            enabled: pw.text.length >= root.pwMinLength && !root.connecting
                            onClicked: root.join()
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: joinBtn.enabled ? Theme.accent : Theme.tile
                                Behavior on color { TweenColor { duration: Theme.durFast } }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "Join"
                                color: joinBtn.enabled ? Theme.textOnAccent : Theme.faint
                                font.family: Theme.font; font.pixelSize: Theme.fontSm; font.weight: Theme.weightSemibold
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Theme.listFooterHeight

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: Theme.space8; rightMargin: Theme.space8 }
            height: Theme.borderThin
            color: Theme.line
        }
        Row {
            anchors { left: parent.left; leftMargin: Theme.space4; verticalCenter: parent.verticalCenter }
            spacing: Theme.space4
            FooterButton { label: "Rescan"; onClicked: Sys.scanWifi() }
            FooterButton { visible: Sys.wifiName !== ""; label: "Disconnect"; onClicked: Sys.disconnectWifi() }
            FooterButton { label: "Wi-Fi Settings…"; onClicked: Sys.openWifiSettings() }
        }
    }

    component FooterButton: MouseArea {
        id: fb
        property string label: ""
        width: fbText.implicitWidth + 20; height: Theme.listActionHeight
        hoverEnabled: true
        Rectangle { anchors.fill: parent; radius: height / 2; color: fb.containsMouse ? Theme.tile : Theme.transparent }
        Text { id: fbText; anchors.centerIn: parent; text: fb.label; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontMd }
    }
}
