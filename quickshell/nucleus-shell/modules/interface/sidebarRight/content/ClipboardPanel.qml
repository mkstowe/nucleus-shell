import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.components

Item {
    id: root

    property var entries: []
    property bool cliphistAvailable: false

    function parseEntries(text) {
        return text.split("\n").map(line => line.trim()).filter(line => line.length > 0).map(line => {
            const match = line.match(/^([0-9]+)\t?(.*)$/);
            const preview = match && match[2] !== "" ? match[2] : line;
            return {
                raw: line,
                preview: preview
            };
        });
    }

    function refresh() {
        loadClipboard.running = true;
    }

    function copyEntry(rawEntry) {
        if (!rawEntry)
            return;

        decodeClipboard.command = ["sh", "-c", "printf '%s\n' \"$1\" | cliphist decode | wl-copy", "sh", rawEntry];
        decodeClipboard.running = true;
    }

    function clearHistory() {
        clearClipboard.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 8000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: loadClipboard
        running: false
        command: ["sh", "-c", "if command -v cliphist >/dev/null 2>&1; then printf '__AVAILABLE__\\n'; cliphist list | head -n 20; fi"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.cliphistAvailable = lines.length > 0 && lines[0].trim() === "__AVAILABLE__";
                root.entries = root.parseEntries(lines.slice(root.cliphistAvailable ? 1 : 0).join("\n"));
            }
        }
    }

    Process {
        id: decodeClipboard
        running: false
    }

    Process {
        id: clearClipboard
        running: false
        command: ["sh", "-c", "command -v cliphist >/dev/null 2>&1 && cliphist wipe"]

        onExited: root.refresh()
    }

    Flickable {
        id: clipboardFlick
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: clipboardContent.height
        ScrollBar.vertical: ScrollBar {}

        Column {
            id: clipboardContent
            width: clipboardFlick.width
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
                        tooltipText: "Refresh clipboard"
                        tooltipOffsetY: Metrics.margin(48)
                        onButtonClicked: root.refresh()
                    }
                }
            }

            StyledRect {
                width: parent.width
                radius: Metrics.radius("large")
                color: Appearance.colors.colLayer2
                implicitHeight: sectionColumn.implicitHeight + Metrics.margin("small") * 2

                Column {
                    id: sectionColumn
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
                                icon: "content_paste"
                                iconSize: Metrics.iconSize("normal")
                                color: Appearance.colors.colOnLayer2
                            }

                            StyledText {
                                text: "Clipboard History"
                                font.pixelSize: Metrics.fontSize("normal")
                                color: Appearance.colors.colOnLayer2
                                animate: false
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledButton {
                            visible: root.cliphistAvailable && root.entries.length > 0
                            text: "Clear"
                            icon: "clear_all"
                            secondary: true
                            implicitHeight: 32
                            implicitWidth: 88
                            onClicked: root.clearHistory()
                        }
                    }

                    StyledText {
                        visible: !root.cliphistAvailable
                        text: "Clipboard history requires cliphist."
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Metrics.fontSize("small")
                        animate: false
                    }

                    StyledText {
                        visible: root.cliphistAvailable && root.entries.length < 1
                        text: "No clipboard history yet"
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Metrics.fontSize("small")
                        animate: false
                    }

                    Repeater {
                        model: root.entries

                        Rectangle {
                            id: clipboardRow
                            required property var modelData

                            width: sectionColumn.width
                            implicitHeight: 46
                            radius: Metrics.radius("large")
                            color: rowMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.m3colors.m3surfaceContainerLowest

                            Behavior on color {
                                ColorAnimation {
                                    duration: Metrics.chronoDuration("small")
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.copyEntry(clipboardRow.modelData.raw)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Metrics.margin("small")
                                anchors.rightMargin: Metrics.margin("small")
                                spacing: Metrics.spacing(10)

                                MaterialSymbol {
                                    icon: "content_paste"
                                    iconSize: Metrics.iconSize("normal")
                                    color: Appearance.colors.colSubtext
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    StyledText {
                                        text: clipboardRow.modelData.preview
                                        color: Appearance.colors.colOnLayer2
                                        font.pixelSize: Metrics.fontSize("small")
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        animate: false
                                    }

                                    StyledText {
                                        text: "Click to copy again"
                                        color: Appearance.colors.colSubtext
                                        font.pixelSize: Metrics.fontSize("smaller")
                                        animate: false
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
