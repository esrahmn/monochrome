import QtQuick
import QtQuick.Effects
import "../../core"
import "../../shared/components"

// Notification toasts, drawn inside the island. No window and no frame of their own:
// the island is the surface and each notification is a tile on it.
Item {
    id: root

    property string panelScreen: ""

    readonly property int toastWidth: 380
    readonly property int toastInset: Theme.space12
    readonly property int notifPadX: 16
    readonly property int notifPadTop: 20
    readonly property int notifPadBottom: 18
    readonly property int notifMaxHeight: 320
    readonly property int notifImageSize: 56
    readonly property int notifImageGap: 14
    readonly property int notifCloseSize: 28
    readonly property int notifActionHeight: 40
    readonly property int notifTextInset: 46
    readonly property int notifSlideFrom: 32
    readonly property int notifDismissDelay: 280

    readonly property int count: Sys.toastCount
    readonly property real wantHeight: count > 0 ? col.implicitHeight + toastInset * 2 : 0
    // Keeps the last height while the final toast leaves, so the island closes with its own spring
    // instead of snapping shut the moment the list is empty.
    property real keptHeight: 0
    onWantHeightChanged: if (wantHeight > 0) keptHeight = wantHeight
    Component.onCompleted: keptHeight = wantHeight

    implicitWidth: toastWidth
    implicitHeight: wantHeight > 0 ? wantHeight : keptHeight

    Column {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.toastInset
        width: Math.min(root.width, root.toastWidth) - root.toastInset * 2
        spacing: Theme.space8

        Repeater {
            model: Sys.toastItems

            delegate: Rectangle {
                id: card
                required property var modelData
                width: col.width

                implicitHeight: Math.min(root.notifMaxHeight, row.implicitHeight + root.notifPadTop + root.notifPadBottom)
                // Concentric with the island's corner: the card sits toastInset px inside it.
                radius: Theme.radiusInside(root.toastInset)
                color: Theme.tile
                clip: true

                // Arrives with a short fade and slide. How long it stays is decided by Notifs.
                property real appear: 0
                NumberAnimation on appear { from: 0; to: 1; duration: Theme.durBase; easing.type: Theme.easeOut }
                opacity: appear
                transform: Translate { y: -root.notifSlideFrom * (1 - card.appear) }

                property bool leaving: false
                function beginLeave() {
                    if (card.leaving)
                        return;
                    card.leaving = true;
                    try { card.modelData.dismiss(); } catch (e) {}
                }

                readonly property var defaultAction: (modelData.actions ?? []).find(a => a.identifier === "default") ?? null
                readonly property string img: modelData.image || ""

                Timer {
                    id: dismissLater
                    interval: root.notifDismissDelay
                    onTriggered: card.beginLeave("dismiss")
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !card.leaving
                    onClicked: {
                        if (card.defaultAction) {
                            dismissLater.restart();
                            card.defaultAction.invoke();
                        } else {
                            card.beginLeave("dismiss");
                        }
                    }
                }

                MouseArea {
                    id: closeBtn
                    anchors { top: parent.top; right: parent.right; margins: Theme.space12 }
                    width: root.notifCloseSize; height: root.notifCloseSize
                    z: 5
                    hoverEnabled: true
                    enabled: !card.leaving
                    onClicked: card.beginLeave("dismiss")
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusCard
                        color: closeBtn.containsMouse ? Theme.tilePress : Theme.tile
                        Behavior on color { TweenColor { duration: Theme.durFast } }
                    }
                    Canvas {
                        anchors.centerIn: parent
                        width: Settings.notifCloseIconSize; height: Settings.notifCloseIconSize
                        property color c: Theme.text
                        onCChanged: requestPaint()
                        onPaint: {
                            const x = getContext("2d"); x.reset();
                            x.strokeStyle = c; x.lineWidth = 1.8; x.lineCap = "round";
                            x.beginPath(); x.moveTo(1, 1); x.lineTo(11, 11); x.moveTo(11, 1); x.lineTo(1, 11); x.stroke();
                        }
                    }
                }

                Row {
                    id: row
                    anchors {
                        left: parent.left; right: parent.right; top: parent.top
                        leftMargin: root.notifPadX
                        rightMargin: root.notifTextInset
                        topMargin: root.notifPadTop
                    }
                    spacing: root.notifImageGap

                    Item {
                        id: pic
                        visible: card.img !== "" && picImg.status === Image.Ready
                        width: root.notifImageSize; height: root.notifImageSize
                        Image {
                            id: picImg
                            anchors.fill: parent
                            source: card.img
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 112; sourceSize.height: 112
                            asynchronous: true
                            visible: false
                        }
                        Rectangle { id: picMask; anchors.fill: parent; radius: Theme.radiusCard; visible: false; layer.enabled: true }
                        MultiEffect {
                            anchors.fill: parent
                            source: picImg
                            saturation: -1.0
                            maskEnabled: true
                            maskSource: picMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                    }

                    Column {
                        id: content
                        width: row.width - (pic.visible ? pic.width + row.spacing : 0)
                        spacing: Theme.space8

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: card.modelData.appName
                            color: Theme.dim
                            font.family: Theme.font; font.pixelSize: Theme.fontMd
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: card.modelData.summary
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontLg; font.weight: Theme.weightSemibold
                        }
                        Text {
                            visible: text !== ""
                            width: parent.width
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            text: card.modelData.body
                            color: Theme.text
                            font.family: Theme.font; font.pixelSize: Theme.fontMd
                            lineHeightMode: Text.FixedHeight
                            lineHeight: Math.round(Theme.fontMd * Theme.lineProse)
                            textFormat: Text.PlainText
                        }

                        Row {
                            id: actionRow
                            spacing: Theme.space8

                            visible: (card.modelData.actions ?? []).some(a => a.identifier !== "default")

                            Repeater {
                                model: card.modelData.actions ?? []

                                delegate: MouseArea {
                                    id: act
                                    required property var modelData

                                    visible: modelData.identifier !== "default"

                                    width: (actText.text ? actText.implicitWidth : 0) + 24
                                    height: root.notifActionHeight
                                    hoverEnabled: true

                                    onClicked: {
                                        dismissLater.restart();
                                        act.modelData.invoke();
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.radiusCard
                                        color: act.containsMouse ? Theme.tileHover : Theme.tile
                                        Behavior on color { TweenColor { duration: Theme.durFast } }
                                    }

                                    Text {
                                        id: actText
                                        anchors.centerIn: parent
                                        text: modelData.text || modelData.identifier || "Action"
                                        color: Theme.text
                                        font.family: Theme.font; font.pixelSize: Theme.fontMd; font.weight: Theme.weightMedium
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
