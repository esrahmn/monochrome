import "../../core"
import "../../shared/components"
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string panelScreen: ""
    readonly property bool shown: Sys.activePanel === "calendar" && Sys.activePanelScreen === panelScreen
    readonly property int weatherIconSize: 30
    readonly property int calendarWidth: 400
    readonly property int calendarNavSize: 32
    readonly property int calendarWeekdayHeight: 28
    readonly property int calendarDayHeight: 42
    readonly property int calendarDayCircle: 36
    property var selectedDate: new Date()
    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()

    // Show only the weeks needed by this month, starting on Monday.
    readonly property var cells: {
        const lead = (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7;
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
        const weekCount = Math.ceil((lead + daysInMonth) / 7);
        const today = new Date();
        const out = [];
        for (let i = 0; i < weekCount * 7; i++) {
            const d = new Date(viewYear, viewMonth, 1 - lead + i);
            out.push({
                date: d,
                day: d.getDate(),
                inMonth: d.getMonth() === viewMonth,
                today: d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate()
            });
        }
        return out;
    }

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    function selectDate(d) {
        selectedDate = d;
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    implicitWidth: calendarWidth
    implicitHeight: col.implicitHeight + Theme.space16 * 2
    width: parent ? parent.width : implicitWidth
    height: parent ? parent.height : implicitHeight
    onShownChanged: {
        if (!shown)
            return ;

        Sys.weather.ensureFresh();
        const d = new Date();
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
        selectedDate = d;
    }
    onPanelScreenChanged: {
        if (!shown)
            return ;

        Sys.weather.ensureFresh();
        const d = new Date();
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
        selectedDate = d;
    }

    Item {
        id: card

        readonly property int padding: Theme.space16
        width: root.width
        height: root.parent ? Math.min(col.implicitHeight + card.padding * 2, root.height) : col.implicitHeight + card.padding * 2

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }

        Flickable {
            id: flick

            anchors { fill: parent; margins: card.padding }
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col

                width: flick.width
                spacing: Theme.space16

                    Rectangle {
                        Layout.fillWidth: true
                        visible: Sys.weather.hasLocation
                        implicitHeight: wxCol.implicitHeight + Theme.space16 * 2
                        radius: Theme.radiusCard
                        color: Theme.tile

                        ColumnLayout {
                            id: wxCol

                            spacing: Theme.space12

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Theme.space16
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space12

                                Glyph {
                                    visible: Sys.weather.available
                                    Layout.preferredWidth: root.weatherIconSize
                                    Layout.preferredHeight: root.weatherIconSize
                                    name: Sys.weather.available ? Sys.weather.iconFor(Sys.weather.current.code, Sys.weather.current.isDay) : ""
                                    color: Theme.text
                                }

                                Text {
                                    text: Sys.weather.available ? Math.round(Sys.weather.current.temp) + "°" : "–"
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.font2xl
                                    font.weight: Theme.weightSemibold
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: Sys.weather.available ? Sys.weather.describe(Sys.weather.current.code) : (Sys.weather.loading ? "Updating…" : (Sys.weather.error !== "" ? Sys.weather.error : "No data yet"))
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontLg
                                        font.weight: Theme.weightMedium
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: String(Sys.weather.placeName || "").split(",")[0].trim() + (Sys.weather.available ? "  ·  Feels like " + Math.round(Sys.weather.current.feels) + "°" : "")
                                        color: Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSm
                                        elide: Text.ElideRight
                                }

                            }

                            }

                            Row {
                            id: wxRow

                                readonly property real cw: width / Math.max(1, Sys.weather.daily.length)

                                Layout.fillWidth: true
                                visible: Sys.weather.daily.length > 0

                                Repeater {
                                    model: Sys.weather.daily

                                    delegate: Column {
                                        id: wxDay

                                        required property var modelData

                                        width: wxRow.cw
                                        spacing: Theme.space4

                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: Qt.formatDate(new Date(wxDay.modelData.date + "T00:00:00"), "ddd")
                                            color: Theme.dim
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontXs
                                        }

                                        Glyph {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: Theme.iconLg
                                            height: Theme.iconLg
                                            name: Sys.weather.iconFor(wxDay.modelData.code, true)
                                            color: Theme.text
                                        }

                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: Math.round(wxDay.modelData.max) + "°"
                                            color: Theme.text
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSm
                                            font.weight: Theme.weightMedium
                                        }

                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: Math.round(wxDay.modelData.min) + "°"
                                            color: Theme.dim
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSm
                                        }

                                    }

                                }

                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Weather data by Open-Meteo.com"
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: Theme.fontXs
                            }

                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: calCol.implicitHeight + Theme.space16 * 2
                        radius: Theme.radiusCard
                        color: Theme.tile

                        ColumnLayout {
                            id: calCol

                            spacing: Theme.space12

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Theme.space16
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    Layout.fillWidth: true
                                    text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontLg
                                    font.weight: Theme.weightSemibold

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            const d = new Date();
                                            root.viewYear = d.getFullYear();
                                            root.viewMonth = d.getMonth();
                                            root.selectedDate = d;
                                        }
                                    }

                                }

                                Repeater {
                                    model: [-1, 1]

                                    delegate: MouseArea {
                                        id: nav

                                        required property int modelData

                                        Layout.preferredWidth: root.calendarNavSize
                                        Layout.preferredHeight: root.calendarNavSize
                                        hoverEnabled: true
                                        onClicked: root.shiftMonth(modelData)

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.radiusControl
                                            color: nav.containsMouse ? Theme.tileHover : Theme.transparent
                                        }

                                        Glyph {
                                            anchors.centerIn: parent
                                            width: Theme.iconMd
                                            height: Theme.iconMd
                                            name: "chevron"
                                            rotation: nav.modelData < 0 ? 90 : -90
                                            color: Theme.text
                                        }

                                }

                            }

                            }

                            Grid {
                                id: grid

                                readonly property real cw: calCol.width / 7

                                Layout.preferredWidth: calCol.width
                                columns: 7

                                Repeater {
                                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                                    delegate: Text {
                                        required property string modelData

                                        width: grid.cw
                                        height: root.calendarWeekdayHeight
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: modelData
                                        color: Theme.faint
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSm
                                        font.weight: Theme.weightMedium
                                    }

                                }

                                Repeater {
                                    model: root.cells

                                    delegate: Item {
                                        id: dayCell

                                        required property var modelData
                                        readonly property bool isSelected: modelData.date.getFullYear() === root.selectedDate.getFullYear() && modelData.date.getMonth() === root.selectedDate.getMonth() && modelData.date.getDate() === root.selectedDate.getDate()

                                        width: grid.cw
                                        height: root.calendarDayHeight

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: root.calendarDayCircle
                                            height: root.calendarDayCircle
                                            radius: Math.min(width, height) / 2
                                            color: dayArea.containsMouse && !isSelected ? Theme.tileHover : (isSelected ? Theme.accent : Theme.transparent)
                                            border.width: modelData.today && !isSelected ? 1 : 0
                                            border.color: Theme.accent
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day
                                            color: isSelected ? Theme.textOnAccent : (modelData.inMonth ? Theme.text : Theme.faint)
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontLg
                                            font.weight: isSelected || modelData.today ? Theme.weightSemibold : Theme.weightRegular
                                        }

                                        MouseArea {
                                            id: dayArea

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.selectDate(dayCell.modelData.date)
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
