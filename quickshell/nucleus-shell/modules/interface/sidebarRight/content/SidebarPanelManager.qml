import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.functions
import qs.services
import qs.config
import qs.modules.components

StyledRect {
    id: root

    Layout.fillWidth: true
    radius: Metrics.radius("normal")
    color: Appearance.colors.colLayer1

    readonly property string defaultPanel: "activity"
    property string activePanel: defaultPanel
    property date visibleMonth: new Date(Time.date.getFullYear(), Time.date.getMonth(), 1)
    property var screenshotItems: []
    property var downloadItems: []

    readonly property string screenshotsPath: FileUtils.trimFileProtocol(Directories.pictures) + "/screenshots"
    readonly property string downloadsPath: FileUtils.trimFileProtocol(Directories.downloads)
    readonly property string panelTitle: activePanel === "calendar" ? Qt.formatDate(visibleMonth, "MMMM yyyy") : activePanel === "clipboard" ? "Clipboard History" : "Recent Activity"
    readonly property string panelSubtitle: activePanel === "calendar" ? Qt.formatDate(Time.date, "dddd, MMMM d") : activePanel === "clipboard" ? "Recent clipboard entries" : NotifServer.data.length + " notifications, screenshots, and downloads"

    function formatRelativeTime(dateValue) {
        if (!dateValue)
            return "just now";

        const diffMs = Math.max(0, Time.date.getTime() - new Date(dateValue).getTime());
        const minutes = Math.floor(diffMs / 60000);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);

        if (minutes < 1)
            return "just now";
        if (minutes < 60)
            return minutes + "m ago";
        if (hours < 24)
            return hours + "h ago";
        if (days < 7)
            return days + "d ago";
        return Qt.formatDate(new Date(dateValue), "MMM d");
    }

    function parseFileList(text, kind, basePath) {
        return text.split("\n").map(line => line.trim()).filter(line => line.length > 0).map(line => {
            const parts = line.split("\t");
            if (parts.length < 2)
                return null;
            const modifiedSeconds = Number(parts[0]);
            const fileName = parts.slice(1).join("\t");
            return {
                kind: kind,
                title: fileName,
                subtitle: formatRelativeTime(new Date(modifiedSeconds * 1000)),
                icon: kind === "screenshot" ? "image" : "download",
                path: basePath + "/" + fileName
            };
        }).filter(item => item !== null);
    }

    function triggerActivityRefresh() {
        screenshotProcess.running = true;
        downloadsProcess.running = true;
    }

    function openPath(path) {
        if (path)
            Quickshell.execDetached(["xdg-open", path]);
    }

    Component.onCompleted: triggerActivityRefresh()

    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: root.triggerActivityRefresh()
    }

    Process {
        id: screenshotProcess
        running: false
        command: ["sh", "-c", "find \"" + root.screenshotsPath + "\" -maxdepth 1 -type f -printf '%T@\\t%f\\n' 2>/dev/null | sort -nr | head -n 3"]

        stdout: StdioCollector {
            onStreamFinished: root.screenshotItems = root.parseFileList(text, "screenshot", root.screenshotsPath)
        }
    }

    Process {
        id: downloadsProcess
        running: false
        command: ["sh", "-c", "find \"" + root.downloadsPath + "\" -maxdepth 1 -type f -printf '%T@\\t%f\\n' 2>/dev/null | sort -nr | head -n 3"]

        stdout: StdioCollector {
            onStreamFinished: root.downloadItems = root.parseFileList(text, "download", root.downloadsPath)
        }
    }

    Connections {
        target: Globals.visiblility

        function onSidebarRightChanged() {
            if (Globals.visiblility.sidebarRight) {
                root.activePanel = root.defaultPanel;
                root.visibleMonth = new Date(Time.date.getFullYear(), Time.date.getMonth(), 1);
                root.triggerActivityRefresh();
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
                    text: root.panelTitle
                    font.pixelSize: Metrics.fontSize("large")
                    font.family: Metrics.fontFamily("title")
                    animate: false
                }

                StyledText {
                    text: root.panelSubtitle
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
                    text: "Calendar"
                    icon: "calendar_month"
                    secondary: root.activePanel !== "calendar"
                    checked: root.activePanel === "calendar"
                    onClicked: root.activePanel = "calendar"
                }

                StyledButton {
                    Layout.fillWidth: true
                    text: "Activity"
                    icon: "schedule"
                    secondary: root.activePanel !== "activity"
                    checked: root.activePanel === "activity"
                    onClicked: root.activePanel = "activity"
                }

                StyledButton {
                    Layout.fillWidth: true
                    text: "Clipboard"
                    icon: "content_paste"
                    secondary: root.activePanel !== "clipboard"
                    checked: root.activePanel === "clipboard"
                    onClicked: root.activePanel = "clipboard"
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: root.activePanel === "calendar" ? calendarPanel : root.activePanel === "clipboard" ? clipboardPanel : activityPanel
        }
    }

    Component {
        id: calendarPanel

        CalendarPanel {
            visibleMonth: root.visibleMonth
            onVisibleMonthChanged: root.visibleMonth = visibleMonth
        }
    }

    Component {
        id: activityPanel

        Item {
            Flickable {
                id: activityColumn
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: activityContent.height
                ScrollBar.vertical: ScrollBar {}

                Column {
                    id: activityContent
                    width: activityColumn.width
                    spacing: Metrics.spacing(10)

                    RowLayout {
                        width: parent.width

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledRect {
                            color: "transparent"
                            radius: Metrics.radius("large")
                            implicitHeight: refreshButton.height + Metrics.margin("tiny")
                            implicitWidth: refreshButton.width + Metrics.margin("tiny")
                            Layout.rightMargin: Metrics.margin("small")

                            MaterialSymbolButton {
                                id: refreshButton
                                anchors.centerIn: parent
                                icon: "refresh"
                                iconSize: Metrics.iconSize("huge")
                                tooltipText: "Refresh activity"
                                tooltipOffsetY: Metrics.margin(48)
                                onButtonClicked: root.triggerActivityRefresh()
                            }
                        }
                    }

                    ActivitySection {
                        width: parent.width
                        title: "Notifications"
                        icon: "notifications"
                        emptyText: "No recent notifications"
                        items: NotifServer.history.slice(-3).reverse().map(notif => ({
                                    title: notif.summary || notif.appName || "Notification",
                                    subtitle: (notif.appName || "System") + " • " + Qt.formatTime(notif.time, "h:mm AP"),
                                    icon: "notifications",
                                    rawNotif: notif
                                }))
                        actionText: "Clear"
                        onActionClicked: {
                            const snapshot = NotifServer.data.slice();
                            for (let i = 0; i < snapshot.length; i++) {
                                const n = snapshot[i];
                                if (n?.notification)
                                    n.notification.dismiss();
                            }
                        }
                        onItemActivated: item => {
                            if (item?.rawNotif?.notification)
                                item.rawNotif.notification.dismiss();
                        }
                    }

                    ActivitySection {
                        width: parent.width
                        title: "Screenshots"
                        icon: "photo_camera"
                        emptyText: "No screenshots yet"
                        items: root.screenshotItems
                        actionText: "Open"
                        onItemActivated: item => root.openPath(item.path)
                        onActionClicked: root.openPath(root.screenshotsPath)
                    }

                    ActivitySection {
                        width: parent.width
                        title: "Downloads"
                        icon: "download"
                        emptyText: "No downloads found"
                        items: root.downloadItems
                        actionText: "Open"
                        onItemActivated: item => root.openPath(item.path)
                        onActionClicked: root.openPath(root.downloadsPath)
                    }
                }
            }
        }
    }

    Component {
        id: clipboardPanel

        ClipboardPanel {}
    }

    component ActivitySection: StyledRect {
        id: sectionRoot

        property string title: ""
        property string icon: "schedule"
        property string emptyText: ""
        property string actionText: ""
        property var items: []
        signal itemActivated(var item)
        signal actionClicked

        color: Appearance.colors.colLayer2
        radius: Metrics.radius("large")
        implicitHeight: sectionContent.implicitHeight + Metrics.margin("small") * 2

        Column {
            id: sectionContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Metrics.margin("small")
            spacing: Metrics.spacing(6)

            RowLayout {
                width: parent.width

                RowLayout {
                    spacing: Metrics.spacing(6)

                    MaterialSymbol {
                        icon: sectionRoot.icon
                        iconSize: Metrics.iconSize("normal")
                        color: Appearance.colors.colOnLayer2
                    }

                    StyledText {
                        text: sectionRoot.title
                        font.pixelSize: Metrics.fontSize("normal")
                        color: Appearance.colors.colOnLayer2
                        animate: false
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledButton {
                    visible: sectionRoot.actionText !== ""
                    text: sectionRoot.actionText
                    icon: sectionRoot.actionText === "Clear" ? "clear_all" : "open_in_new"
                    secondary: true
                    implicitHeight: 32
                    implicitWidth: 88
                    onClicked: sectionRoot.actionClicked()
                }
            }

            StyledText {
                visible: sectionRoot.items.length < 1
                text: sectionRoot.emptyText
                color: Appearance.colors.colSubtext
                font.pixelSize: Metrics.fontSize("small")
                animate: false
            }

            Repeater {
                model: sectionRoot.items

                Rectangle {
                    id: activityRow
                    required property var modelData

                    width: sectionContent.width
                    implicitHeight: 46
                    radius: Metrics.radius("large")
                    color: activityMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.m3colors.m3surfaceContainerLowest

                    Behavior on color {
                        ColorAnimation {
                            duration: Metrics.chronoDuration("small")
                        }
                    }

                    MouseArea {
                        id: activityMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !!activityRow.modelData.path || !!activityRow.modelData.rawNotif?.notification
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: sectionRoot.itemActivated(activityRow.modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.margin("small")
                        anchors.rightMargin: Metrics.margin("small")
                        spacing: Metrics.spacing(10)

                        MaterialSymbol {
                            icon: activityRow.modelData.icon || sectionRoot.icon
                            iconSize: Metrics.iconSize("normal")
                            color: Appearance.colors.colSubtext
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                text: activityRow.modelData.title
                                color: Appearance.colors.colOnLayer2
                                font.pixelSize: Metrics.fontSize("small")
                                elide: Text.ElideRight
                                animate: false
                            }

                            StyledText {
                                text: activityRow.modelData.subtitle
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Metrics.fontSize("smaller")
                                elide: Text.ElideRight
                                animate: false
                            }
                        }
                    }
                }
            }
        }
    }
}
