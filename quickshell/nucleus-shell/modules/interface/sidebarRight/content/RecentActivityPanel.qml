import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.components
import qs.modules.functions
import qs.services

StyledRect {
    id: root

    Layout.fillWidth: true
    radius: Metrics.radius("normal")
    color: Appearance.colors.colLayer1
    implicitHeight: panelColumn.implicitHeight + Metrics.margin("small") * 2

    property var screenshotItems: []
    property var downloadItems: []

    readonly property string screenshotsPath: FileUtils.trimFileProtocol(Directories.pictures) + "/screenshots"
    readonly property string downloadsPath: FileUtils.trimFileProtocol(Directories.downloads)

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

    function triggerRefresh() {
        screenshotProcess.running = true;
        downloadsProcess.running = true;
    }

    Component.onCompleted: triggerRefresh()

    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: root.triggerRefresh()
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

    ColumnLayout {
        id: panelColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Metrics.margin("small")
        spacing: Metrics.margin("small")

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacing(3)

                StyledText {
                    text: "Recent Activity"
                    font.pixelSize: Metrics.fontSize("large")
                    font.family: Metrics.fontFamily("title")
                    animate: false
                }

                StyledText {
                    text: "Notifications, screenshots, and downloads"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Metrics.fontSize("small")
                    animate: false
                }
            }

            StyledButton {
                text: "Refresh"
                icon: "refresh"
                secondary: true
                implicitWidth: 108
                onClicked: root.triggerRefresh()
            }
        }

        ActivitySection {
            Layout.fillWidth: true
            title: "Notifications"
            icon: "notifications"
            emptyText: "No recent notifications"
            items: NotifServer.history.slice(-2).reverse().map(notif => ({
                        title: notif.summary || notif.appName || "Notification",
                        subtitle: (notif.appName || "System") + " • " + Qt.formatTime(notif.time, "h:mm AP"),
                        icon: "notifications"
                    }))
        }

        ActivitySection {
            Layout.fillWidth: true
            title: "Screenshots"
            icon: "photo_camera"
            emptyText: "No screenshots yet"
            items: root.screenshotItems
            onItemActivated: item => Quickshell.execDetached(["xdg-open", item.path])
            onActionClicked: Quickshell.execDetached(["xdg-open", root.screenshotsPath])
        }

        ActivitySection {
            Layout.fillWidth: true
            title: "Downloads"
            icon: "download"
            emptyText: "No downloads found"
            items: root.downloadItems
            onItemActivated: item => Quickshell.execDetached(["xdg-open", item.path])
            onActionClicked: Quickshell.execDetached(["xdg-open", root.downloadsPath])
        }
    }

    component ActivitySection: StyledRect {
        id: sectionRoot

        property string title: ""
        property string icon: "schedule"
        property string emptyText: ""
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
                    visible: sectionRoot.title === "Screenshots" || sectionRoot.title === "Downloads"
                    text: "Open"
                    icon: "open_in_new"
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
                        enabled: !!activityRow.modelData.path
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
