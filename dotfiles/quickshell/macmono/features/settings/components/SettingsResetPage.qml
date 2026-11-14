import QtQuick
import "../../../core"

Column {
    id: root

    property int changedCount: 0
    property string pageKey: ""
    signal confirmed()

    property bool armed: false
    spacing: 0

    onPageKeyChanged: { armed = false; confirmTimer.stop(); }
    onChangedCountChanged: if (changedCount === 0) { armed = false; confirmTimer.stop(); }

    Timer {
        id: confirmTimer
        interval: SettingsMetrics.settingsConfirmMs
        onTriggered: root.armed = false
    }

    Item {
        width: root.width
        height: SettingsMetrics.settingsGroupSpacing
    }

    Rectangle {
        width: root.width
        height: resetRow.implicitHeight
        radius: Theme.radiusCard
        color: Theme.tile
        border.width: Theme.borderThin
        border.color: Theme.line

        SettingsRow {
            id: resetRow
            width: parent.width
            title: "Reset this page"

            SettingsButton {
                label: root.armed ? "Tap again to reset" : "Reset"
                primary: root.armed
                enabled: root.changedCount > 0
                onClicked: {
                    if (!root.armed) {
                        root.armed = true;
                        confirmTimer.restart();
                        return;
                    }
                    confirmTimer.stop();
                    root.armed = false;
                    root.confirmed();
                }
            }
        }
    }

    SettingsNote {
        width: root.width
        topPadding: Theme.space8
        text: root.changedCount > 0
            ? "Sets " + root.changedCount + (root.changedCount === 1 ? " option" : " options")
              + " on this page back to default. Nothing is saved until you Apply."
            : "Everything on this page is already at its default."
    }
}
