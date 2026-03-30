import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config
import qs.modules.components

Item {
    id: root

    property date visibleMonth: new Date(Time.date.getFullYear(), Time.date.getMonth(), 1)
    readonly property date today: new Date(Time.date.getFullYear(), Time.date.getMonth(), Time.date.getDate())
    readonly property int leadingDays: firstDayOffset(visibleMonth)
    readonly property var weekdayLabels: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    function firstDayOffset(date) {
        return new Date(date.getFullYear(), date.getMonth(), 1).getDay();
    }

    function datesMatch(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function cellDate(index) {
        const dayNumber = index - leadingDays + 1;
        return new Date(visibleMonth.getFullYear(), visibleMonth.getMonth(), dayNumber);
    }

    function isCurrentMonth(date) {
        return date.getMonth() === visibleMonth.getMonth() && date.getFullYear() === visibleMonth.getFullYear();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.margin("small")

        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacing(8)

            StyledButton {
                text: ""
                icon: "chevron_left"
                implicitWidth: 40
                onClicked: root.visibleMonth = new Date(root.visibleMonth.getFullYear(), root.visibleMonth.getMonth() - 1, 1)
            }

            StyledButton {
                Layout.fillWidth: true
                text: "Today"
                icon: "today"
                secondary: true
                onClicked: root.visibleMonth = new Date(Time.date.getFullYear(), Time.date.getMonth(), 1)
            }

            StyledButton {
                text: ""
                icon: "chevron_right"
                implicitWidth: 40
                onClicked: root.visibleMonth = new Date(root.visibleMonth.getFullYear(), root.visibleMonth.getMonth() + 1, 1)
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: Metrics.spacing(6)
            rowSpacing: Metrics.spacing(6)

            Repeater {
                model: root.weekdayLabels

                StyledText {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Metrics.fontSize("small")
                    animate: false
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            columnSpacing: Metrics.spacing(6)
            rowSpacing: Metrics.spacing(6)

            Repeater {
                model: 42

                Rectangle {
                    required property int index

                    readonly property date dateValue: root.cellDate(index)
                    readonly property bool inMonth: root.isCurrentMonth(dateValue)
                    readonly property bool isToday: root.datesMatch(dateValue, root.today)

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Metrics.radius("large")
                    color: isToday ? Appearance.m3colors.m3primaryContainer : inMonth ? Appearance.colors.colLayer2 : Appearance.m3colors.m3surfaceContainerLowest
                    border.width: isToday ? 0 : 1
                    border.color: inMonth ? Appearance.m3colors.m3outlineVariant : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: dateValue.getDate()
                        color: parent.isToday ? Appearance.m3colors.m3onPrimaryContainer : parent.inMonth ? Appearance.colors.colOnLayer2 : Appearance.colors.colOnLayer1Inactive
                        font.pixelSize: Metrics.fontSize(parent.isToday ? "large" : "normal")
                        animate: false
                    }
                }
            }
        }
    }
}
