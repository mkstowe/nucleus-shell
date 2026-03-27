import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config
import qs.modules.components

Item {
    id: clockContainer

    property string displayName: ""
    property string format: isVertical ? "hh\nmm\nAP" : "dddd, MMMM d | h:mm AP"
    property bool isVertical: (ConfigResolver.bar(displayName).position === "left" || ConfigResolver.bar(displayName).position === "right")

    visible: ConfigResolver.bar(displayName).modules.clock.enabled
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: bgRect.implicitWidth
    implicitHeight: bgRect.implicitHeight

    // Let the layout compute size automatically

    Rectangle {
        id: bgRect

        color: isVertical ? "transparent" : Appearance.m3colors.m3paddingContainer
        radius: ConfigResolver.bar(displayName).modules.radius * Config.runtime.appearance.rounding.factor
        // Padding around the text
        implicitWidth: isVertical ? textItem.implicitWidth + 40 : textItem.implicitWidth + Metrics.margin("large")
        implicitHeight: ConfigResolver.bar(displayName).modules.height
    }

    StyledText {
        id: textItem
        anchors.centerIn: parent
        animate: false
        text: Time.format(clockContainer.format)
    }
}
