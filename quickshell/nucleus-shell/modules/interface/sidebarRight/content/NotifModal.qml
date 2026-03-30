import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.interface.notifications
import qs.services
import qs.config
import qs.modules.components

StyledRect {
    id: root

    Layout.fillWidth: true
    radius: Metrics.radius("normal")
    color: Appearance.colors.colLayer1
    property bool dndActive: Config.runtime.notifications.doNotDisturb
    property string activeView: "notifications"
    property date visibleMonth: new Date(Time.date.getFullYear(), Time.date.getMonth(), 1)

    function toggleDnd() {
        Config.updateKey("notifications.doNotDisturb", !dndActive);
    }

    Connections {
        target: Globals.visiblility

        function onSidebarRightChanged() {
            if (Globals.visiblility.sidebarRight) {
                root.activeView = "notifications";
                root.visibleMonth = new Date(Time.date.getFullYear(), Time.date.getMonth(), 1);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.margin("small")
        spacing: Metrics.margin("small")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacing(8)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacing(4)

                StyledText {
                    text: root.activeView === "notifications" ? "Notification History" : Qt.formatDate(root.visibleMonth, "MMMM yyyy")
                    font.pixelSize: Metrics.fontSize("large")
                    font.family: Metrics.fontFamily("title")
                    animate: false
                }

                StyledText {
                    text: root.activeView === "notifications" ? NotifServer.data.length + " Notifications" : Qt.formatDate(Time.date, "dddd, MMMM d")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Metrics.fontSize("small")
                    animate: false
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacing(6)

                StyledButton {
                    Layout.fillWidth: true
                    text: "Notifications"
                    icon: "notifications"
                    secondary: root.activeView !== "notifications"
                    checked: root.activeView === "notifications"
                    onClicked: root.activeView = "notifications"
                }

                StyledButton {
                    Layout.fillWidth: true
                    text: "Calendar"
                    icon: "calendar_month"
                    secondary: root.activeView !== "calendar"
                    checked: root.activeView === "calendar"
                    onClicked: root.activeView = "calendar"
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: root.activeView === "notifications" ? notificationsView : calendarView
        }
    }

    Component {
        id: notificationsView

        Item {
            StyledText {
                anchors.centerIn: parent
                text: "No notifications"
                visible: NotifServer.data.length < 1
                font.pixelSize: Metrics.fontSize("huge")
            }

            StyledButton {
                id: clearButton
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: Metrics.margin(4)
                icon: "clear_all"
                text: "Clear"
                implicitHeight: 40
                implicitWidth: 100
                secondary: true

                onClicked: {
                    const snapshot = NotifServer.data.slice();
                    for (let i = 0; i < snapshot.length; i++) {
                        const n = snapshot[i];
                        if (n?.notification)
                            n.notification.dismiss();
                    }
                }
            }

            StyledButton {
                anchors.bottom: parent.bottom
                anchors.right: clearButton.left
                anchors.bottomMargin: Metrics.margin(4)
                anchors.rightMargin: Metrics.margin(10)
                text: "Silent"
                icon: "do_not_disturb_on"
                implicitHeight: 40
                implicitWidth: 100
                secondary: true
                checkable: true
                checked: Config.runtime.notifications.doNotDisturb

                onClicked: root.toggleDnd()
            }

            ListView {
                id: notifList
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: clearButton.top
                anchors.bottomMargin: Metrics.margin("small")

                clip: true
                spacing: Metrics.spacing(8)
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {}

                model: Config.runtime.notifications.enabled ? NotifServer.history : []

                delegate: NotificationChild {
                    required property var modelData

                    width: notifList.width
                    tracked: true
                    title: modelData.summary
                    body: modelData.body
                    appName: modelData.appName
                    isHistory: true
                    timestamp: Qt.formatTime(modelData.time, "hh:mm")
                    urgency: modelData.urgency
                    image: modelData.image || modelData.appIcon
                    rawNotif: modelData
                    buttons: modelData.actions.map(action => ({
                                "label": action.text,
                                "onClick": () => action.invoke()
                            }))
                }
            }
        }
    }

    Component {
        id: calendarView

        CalendarPanel {
            visibleMonth: root.visibleMonth
            onVisibleMonthChanged: root.visibleMonth = visibleMonth
        }
    }
}
