import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.components
import qs.modules.functions
import qs.services

Item {
    id: workspaceContainer
    property string displayName: screen?.name ?? ""
    property var workspaceIds: Hyprland.workspaceIdsForMonitor(displayName)

    visible: ConfigResolver.bar(displayName).modules.workspaces.enabled
    implicitWidth: bg.implicitWidth
    implicitHeight: ConfigResolver.bar(displayName).modules.height

    Rectangle {
        id: bg

        color: Appearance.m3colors.m3paddingContainer
        radius: ConfigResolver.bar(displayName).modules.radius * Config.runtime.appearance.rounding.factor
        implicitWidth: workspaceRow.implicitWidth + Metrics.margin("large") - 8
        implicitHeight: ConfigResolver.bar(displayName).modules.height

        RowLayout {
            id: workspaceRow

            anchors.centerIn: parent
            spacing: Metrics.spacing(10)

            Repeater {
                model: workspaceIds

                Item {
                    property int wsIndex: modelData
                    property bool occupied: Compositor.isWorkspaceOccupied(wsIndex)
                    property bool focused: wsIndex === Compositor.focusedWorkspaceId

                    width: 26
                    height: 26

                    Rectangle {
                        anchors.centerIn: parent
                        width: focused ? 12 : 10
                        height: width
                        radius: width / 2
                        color: focused
                            ? Appearance.m3colors.m3tertiary
                            : (occupied ? "#FFFFFF" : "transparent")
                        border.width: focused || occupied ? 0 : 2
                        border.color: "#FFFFFF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Compositor.changeWorkspace(wsIndex)
                    }

                }

            }

        }

    }

}
