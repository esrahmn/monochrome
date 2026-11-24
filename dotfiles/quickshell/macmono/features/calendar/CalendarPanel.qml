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

    // Crossfade the outgoing month with the incoming one so the grid never goes blank.
    readonly property int monthSlide: 36
    property int monthSlideDir: 1
    property real oldFade: 0
    property real oldSlide: 0
    property real newFade: 1
    property real newSlide: 0
    property var frozenCells: []
    property string frozenTitle: ""
    property bool crossfading: false

    // Keep 4/5/6-week months from snapping the card height.
    property real gridHeight: Math.ceil(cells.length / 7) * calendarDayHeight
    Behavior on gridHeight {
        Tween {
            duration: Theme.durBase + 60
            easing.type: Theme.easeOut
        }
    }

    // Cards come in one after another when the panel opens, and go out in reverse order when it closes.
    Cascade { id: stagger; open: root.shown; count: 2; step: 70 }
    function intro(order) { return stagger.fade(order); }
    function rise(order) { return Theme.staggerRise * (1 - stagger.fade(order)); }

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

    function animateToMonth(year, month, dir) {
        if (monthAnim.running)
            return;

        if (year === viewYear && month === viewMonth)
            return;

        frozenCells = cells;
        frozenTitle = Qt.formatDate(new Date(viewYear, viewMonth, 1), "MMMM yyyy");
        monthSlideDir = dir >= 0 ? 1 : -1;
        oldFade = 1;
        oldSlide = 0;
        newFade = 0;
        newSlide = monthSlideDir * monthSlide;
        crossfading = true;
        viewYear = year;
        viewMonth = month;
        monthAnim.restart();
    }

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        animateToMonth(d.getFullYear(), d.getMonth(), delta);
    }

    function selectDate(d) {
        selectedDate = d;
        if (d.getFullYear() !== viewYear || d.getMonth() !== viewMonth) {
            const dir = (d.getFullYear() - viewYear) * 12 + d.getMonth() - viewMonth;
            animateToMonth(d.getFullYear(), d.getMonth(), dir);
        }
    }

    SequentialAnimation {
        id: monthAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "oldFade"
                to: 0
                duration: Theme.durFast + 30
                easing.type: Theme.easeOut
            }
            NumberAnimation {
                target: root
                property: "oldSlide"
                to: -root.monthSlideDir * root.monthSlide
                duration: Theme.durBase + 40
                easing.type: Theme.easeOut
            }
            SequentialAnimation {
                PauseAnimation { duration: 70 }
                NumberAnimation {
                    target: root
                    property: "newFade"
                    to: 1
                    duration: Theme.durBase
                    easing.type: Theme.easeOut
                }
            }
            NumberAnimation {
                target: root
                property: "newSlide"
                to: 0
                duration: Theme.durBase + 60
                easing.type: Theme.easeOut
            }
        }
        ScriptAction {
            script: {
                root.crossfading = false;
                root.oldFade = 0;
                root.newFade = 1;
                root.newSlide = 0;
            }
        }
    }

    implicitWidth: calendarWidth
    implicitHeight: col.implicitHeight + Theme.space16 * 2
    width: parent ? parent.width : implicitWidth
    height: parent ? parent.height : implicitHeight
    onShownChanged: {
        if (!shown)
            return ;

        Sys.weather.ensureFresh();
        monthAnim.stop();
        crossfading = false;
        oldFade = 0;
        oldSlide = 0;
        newFade = 1;
        newSlide = 0;
        const d = new Date();
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
        selectedDate = d;
    }
    onPanelScreenChanged: {
        if (!shown)
            return ;

        Sys.weather.ensureFresh();
        monthAnim.stop();
        crossfading = false;
        oldFade = 0;
        oldSlide = 0;
        newFade = 1;
        newSlide = 0;
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
                        opacity: root.intro(0)
                        scale: 0.98 + 0.02 * stagger.back(0)
                        transform: Translate { y: root.rise(0) }

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
                        opacity: root.intro(1)
                        scale: 0.98 + 0.02 * stagger.back(1)
                        transform: Translate { y: root.rise(1) }
                        clip: true

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

                                Item {
                                    Layout.fillWidth: true
                                    implicitHeight: titleNew.implicitHeight

                                    Text {
                                        id: titleNew
                                        width: parent.width
                                        text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                                        opacity: root.crossfading ? root.newFade : 1
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontLg
                                        font.weight: Theme.weightSemibold
                                    }

                                    Text {
                                        width: parent.width
                                        visible: root.crossfading
                                        text: root.frozenTitle
                                        opacity: root.oldFade
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontLg
                                        font.weight: Theme.weightSemibold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectDate(new Date())
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

                            Column {
                                Layout.fillWidth: true
                                spacing: 0

                                Grid {
                                    id: weekRow
                                    width: parent.width
                                    columns: 7

                                    Repeater {
                                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                                        delegate: Text {
                                            required property string modelData

                                            width: weekRow.width / 7
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
                                }

                                Item {
                                    id: dateArea
                                    width: parent.width
                                    height: root.gridHeight
                                    clip: true

                                    CalendarMonth {
                                        width: parent.width
                                        cells: root.cells
                                        selectedDate: root.selectedDate
                                        cellWidth: weekRow.width / 7
                                        dayHeight: root.calendarDayHeight
                                        circleSize: root.calendarDayCircle
                                        live: root.shown
                                        opacity: root.crossfading ? root.newFade : 1
                                        transform: Translate { x: root.newSlide }
                                        onPicked: (d) => root.selectDate(d)
                                    }

                                    CalendarMonth {
                                        width: parent.width
                                        cells: root.frozenCells
                                        selectedDate: root.selectedDate
                                        cellWidth: weekRow.width / 7
                                        dayHeight: root.calendarDayHeight
                                        circleSize: root.calendarDayCircle
                                        live: root.shown
                                        visible: root.crossfading
                                        opacity: root.oldFade
                                        transform: Translate { x: root.oldSlide }
                                        onPicked: (d) => root.selectDate(d)
                                    }
                                }
                            }

                    }

                }

            }

        }

    }

}
