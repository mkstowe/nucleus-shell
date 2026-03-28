import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.components
import qs.services

Item {
    id: launcherButton

    property string displayName: ""
    property bool isVertical: (ConfigResolver.bar(displayName).position === "left" || ConfigResolver.bar(displayName).position === "right")

    visible: ConfigResolver.bar(displayName).modules.launcher.enabled
    Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    ToggleModule {
        id: button
        anchors.centerIn: parent
        icon: "apps"
        iconSize: Metrics.iconSize(22)
        iconColor: Globals.visiblility.launcher ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
        toggle: Globals.visiblility.launcher
        rotation: isVertical ? 270 : 0

        onToggled: function () {
            Globals.visiblility.launcher = !Globals.visiblility.launcher;
        }
    }
}
