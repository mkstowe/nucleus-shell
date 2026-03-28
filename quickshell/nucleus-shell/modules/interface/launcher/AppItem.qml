import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls

import qs.config
import qs.modules.components
import qs.modules.functions

StyledRect {
    id: root
    property bool hovered: false
    property bool selected: false
    required property var entryData

    required property int parentWidth

    width: parentWidth
    height: Metrics.margin(60)
    color: selected ? Qt.alpha(Appearance.m3colors.m3surfaceContainerHighest, 0.16) : "transparent"
    radius: Metrics.radius(10)

    border.width: selected ? 2 : 0
    border.color: Qt.alpha(Appearance.m3colors.m3primary, 0.9)

    Behavior on color {
        PropertyAnimation {
            duration: Metrics.chronoDuration(160)
            easing.type: Easing.InSine
        }
    }

    Behavior on border.width {
        NumberAnimation {
            duration: Metrics.chronoDuration(120)
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.leftMargin: Metrics.margin(24)
        anchors.verticalCenter: parent.verticalCenter

        width: parent.width - Metrics.margin(60)
        spacing: 0

        StyledText {
            font.weight: 400
            text: entryData?.name ?? ""
            font.pixelSize: Metrics.fontSize(24)
            color: root.selected
                ? Qt.alpha(Appearance.m3colors.m3primary, 0.95)
                : (root.hovered ? Appearance.m3colors.m3onSurface : Qt.alpha(Appearance.m3colors.m3onSurface, 0.82))
            animate: false

            Behavior on color {
                PropertyAnimation {
                    duration: Metrics.chronoDuration(160)
                    easing.type: Easing.InSine
                }
            }
        }

        StyledText {
            visible: false
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: {
            if (entryData?.execute) {
                entryData.execute();
                IPCLoader.toggleLauncher();
            }
        }
    }
}
