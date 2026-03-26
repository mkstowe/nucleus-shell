import QtQuick
import QtQuick.Layouts
import Quickshell
import "content/"
import qs.config
import qs.services
import qs.modules.components

Item {
    property string displayName: screen?.name ?? ""
    property bool isHorizontal: (ConfigResolver.bar(displayName).position === "top" || ConfigResolver.bar(displayName).position === "bottom")

    Row {
        id: hCenterRow
        visible: isHorizontal
        anchors.centerIn: parent
        spacing: Metrics.spacing(4)

        WorkspaceModule {}
    }

    RowLayout {
        id: hLeftRow

        visible: isHorizontal
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.spacing(4)
        anchors.leftMargin: ConfigResolver.bar(displayName).density * 0.3

        ToggleModule {
            icon: "left_panel_open"
            iconSize: Metrics.iconSize(22)
            iconColor: Appearance.m3colors.m3error
            toggle: Globals.visiblility.sidebarLeft

            onToggled: function () {
                Globals.visiblility.sidebarLeft = !Globals.visiblility.sidebarLeft;
            }
        }

        MediaPlayerModule {}
    }

    RowLayout {
        id: hRightRow

        visible: isHorizontal
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Metrics.spacing(4)
        anchors.rightMargin: ConfigResolver.bar(displayName).density * 0.3

        SystemUsageModule {}
        ClockModule {}

        ToggleModule {
            icon: "right_panel_open"
            iconSize: Metrics.iconSize(22)
            iconColor: Appearance.m3colors.m3primary
            toggle: Globals.visiblility.sidebarRight

            onToggled: function () {
                Globals.visiblility.sidebarRight = !Globals.visiblility.sidebarRight;
            }
        }
    }

    // Vertical Layout
    Item {
        visible: !isHorizontal
        anchors.top: parent.top
        anchors.topMargin: ConfigResolver.bar(displayName).density * 0.1
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: vRow.implicitHeight
        implicitHeight: vRow.implicitWidth

        Row {
            id: vRow
            anchors.centerIn: parent
            spacing: Metrics.spacing(8)
            rotation: 90

            ToggleModule {
                icon: "menu"
                iconSize: Metrics.iconSize(22)
                iconColor: Appearance.m3colors.m3error
                toggle: Globals.visiblility.sidebarLeft
                rotation: 270

                onToggled: function () {
                    Globals.visiblility.sidebarLeft = !Globals.visiblility.sidebarLeft;
                }
            }

            SystemUsageModule {}
            MediaPlayerModule {}

            SystemTray {
                rotation: 0
            }
        }
    }

    Item {
        visible: !isHorizontal
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 35
        implicitWidth: centerRow.implicitHeight
        implicitHeight: centerRow.implicitWidth

        Row {
            id: centerRow
            anchors.centerIn: parent

            WorkspaceModule {
                rotation: 90
            }
        }
    }

    Item {
        visible: !isHorizontal
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ConfigResolver.bar(displayName).density * 0.1
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: row.implicitHeight
        implicitHeight: row.implicitWidth

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Metrics.spacing(6)
            rotation: 90

            ToggleModule {
                icon: "right_panel_open"
                iconSize: Metrics.iconSize(22)
                iconColor: Appearance.m3colors.m3primary
                toggle: Globals.visiblility.sidebarRight
                rotation: 270

                onToggled: function () {
                    Globals.visiblility.sidebarRight = !Globals.visiblility.sidebarRight;
                }
            }
        }
    }
}
