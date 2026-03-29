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
            spacing: Metrics.spacing(2)

            Repeater {
                model: workspaceIds

                Item {
                    property int wsIndex: modelData
                    property bool occupied: Compositor.isWorkspaceOccupied(wsIndex)
                    property bool focused: wsIndex === Compositor.focusedWorkspaceId

                    width: 26
                    height: 26

                    Rectangle {
                        id: indicator

                        anchors.centerIn: parent
                        width: focused ? 14 : 11
                        height: width
                        radius: width / 2
                        color: focused
                            ? Appearance.m3colors.m3tertiary
                            : (occupied ? Appearance.m3colors.m3onSurface : "transparent")
                        border.width: focused || occupied ? 0 : 2
                        border.color: Appearance.m3colors.m3onSurface

                        Behavior on width {
                            enabled: Config.runtime.appearance.animations.enabled

                            NumberAnimation {
                                duration: Metrics.chronoDuration(180)
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            enabled: Config.runtime.appearance.animations.enabled

                            ColorAnimation {
                                duration: Metrics.chronoDuration(220)
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on border.width {
                            enabled: Config.runtime.appearance.animations.enabled

                            NumberAnimation {
                                duration: Metrics.chronoDuration(180)
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on border.color {
                            enabled: Config.runtime.appearance.animations.enabled

                            ColorAnimation {
                                duration: Metrics.chronoDuration(220)
                                easing.type: Easing.OutCubic
                            }
                        }

                        transform: Scale {
                            origin.x: indicator.width / 2
                            origin.y: indicator.height / 2
                            xScale: focused ? 1.08 : 1.0
                            yScale: focused ? 1.08 : 1.0

                            Behavior on xScale {
                                enabled: Config.runtime.appearance.animations.enabled

                                NumberAnimation {
                                    duration: Metrics.chronoDuration(220)
                                    easing.type: Easing.OutBack
                                }
                            }

                            Behavior on yScale {
                                enabled: Config.runtime.appearance.animations.enabled

                                NumberAnimation {
                                    duration: Metrics.chronoDuration(220)
                                    easing.type: Easing.OutBack
                                }
                            }
                        }
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
