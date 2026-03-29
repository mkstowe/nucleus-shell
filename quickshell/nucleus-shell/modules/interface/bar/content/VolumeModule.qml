import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.components
import qs.services

Item {
    id: volumeModule

    property string displayName: ""
    property bool isVertical: ConfigResolver.bar(displayName).position === "left" || ConfigResolver.bar(displayName).position === "right"
    property int volumePercent: Math.round((Volume.volume ?? 0) * 100)
    property string volumeIcon: {
        if (Volume.muted)
            return "volume_off"
        if (volumePercent <= 0)
            return "volume_mute"
        if (volumePercent < 50)
            return "volume_down"
        return "volume_up"
    }

    visible: ConfigResolver.bar(displayName).modules.volume.enabled
    Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
    implicitWidth: bgRect.implicitWidth
    implicitHeight: bgRect.implicitHeight
    rotation: isVertical ? 270 : 0

    function adjustVolume(delta) {
        Volume.setVolume((Volume.volume ?? 0) + delta)
    }

    Rectangle {
        id: bgRect

        color: Appearance.m3colors.m3paddingContainer
        radius: ConfigResolver.bar(displayName).modules.radius * Config.runtime.appearance.rounding.factor
        implicitWidth: row.implicitWidth + Metrics.margin("large")
        implicitHeight: ConfigResolver.bar(displayName).modules.height
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Metrics.spacing(8)

        MaterialSymbol {
            icon: volumeModule.volumeIcon
            iconSize: Metrics.iconSize(18)
            color: Volume.muted
                ? Appearance.m3colors.m3error
                : Appearance.m3colors.m3onSurfaceVariant
        }

        StyledText {
            animate: false
            text: volumeModule.volumePercent + "%"
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (Volume.defaultSink?.audio)
                Volume.defaultSink.audio.muted = !Volume.defaultSink.audio.muted
        }

        onWheel: wheel => {
            wheel.accepted = true
            if (wheel.angleDelta.y > 0)
                volumeModule.adjustVolume(0.05)
            else if (wheel.angleDelta.y < 0)
                volumeModule.adjustVolume(-0.05)
        }
    }
}
