import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.modules.components
import qs.services

ContentMenu {

    property string displayName: root.screen?.name ?? ""
    property var fillModeOptions: [
        { label: "Cover", value: "cover" },
        { label: "Fit", value: "fit" },
        { label: "Stretch", value: "stretch" },
        { label: "Tile", value: "tile" }
    ]

    title: "Wallpaper"
    description: "Manage your wallpapers"

    ContentCard {

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacing(16)

            ClippingRectangle {
                id: wpContainer

                Layout.fillWidth: true
                Layout.preferredHeight: width * 9 / 16
                Layout.alignment: Qt.AlignHCenter

                radius: Metrics.radius("unsharpenmore")
                color: Appearance.m3colors.m3surfaceContainer
                clip: true

                Image {
                    anchors.fill: parent
                    fillMode: {
                        switch (Config.runtime.appearance.background.fillMode) {
                        case "fit":
                            return Image.PreserveAspectFit
                        case "stretch":
                            return Image.Stretch
                        case "tile":
                            return Image.Tile
                        default:
                            return Image.PreserveAspectCrop
                        }
                    }
                    cache: true

                    property string previewImg: {
                        const displays = Config.runtime.monitors
                        const fallback = Config.runtime.appearance.background.defaultPath

                        if (!displays)
                            return fallback

                        const monitor = displays?.[displayName]
                        return monitor?.wallpaper ?? fallback
                    }

                    source: previewImg + "?t=" + Date.now()
                    opacity: Config.runtime.appearance.background.enabled ? 1 : 0

                    Behavior on opacity { Anim {} }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: "Wallpaper Manager Disabled"
                    font.pixelSize: Metrics.fontSize("title")

                    opacity: !Config.runtime.appearance.background.enabled ? 1 : 0

                    Behavior on opacity { Anim {} }
                }
            }

            StyledButton {
                icon: "wallpaper"
                text: "Change Wallpaper"
                Layout.fillWidth: true

                onClicked: {
                    Quickshell.execDetached([
                        "qs", "ipc",
                        "-p", Quickshell.shellPath("."),
                        "call", "background", "change"
                    ])
                }
            }

            StyledSwitchOption {
                title: "Enabled"
                description: "Enable or disable the wallpaper daemon."
                prefField: "appearance.background.enabled"
            }

            StyledDropDown {
                label: "Wallpaper Mode"
                model: fillModeOptions.map(option => option.label)
                currentIndex: {
                    const idx = fillModeOptions.findIndex(
                        option => option.value === Config.runtime.appearance.background.fillMode
                    )
                    return idx >= 0 ? idx : 0
                }

                onSelectedIndexChanged: index => {
                    const selected = fillModeOptions[index]
                    if (selected)
                        Config.updateKey("appearance.background.fillMode", selected.value)
                }
            }
        }
    }

    ContentCard {

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacing(16)

            StyledText {
                text: "Parallax Effect"
                font.pixelSize: Metrics.fontSize("big")
                font.bold: true
            }

            StyledSwitchOption {
                title: "Enabled"
                description: "Enable or disable wallpaper parallax effect."
                prefField: "appearance.background.parallax.enabled"
            }

            StyledSwitchOption {
                title: "Enabled for Sidebar Left"
                description: "Show parallax when sidebarLeft opens."
                prefField: "appearance.background.parallax.enableSidebarLeft"
            }

            StyledSwitchOption {
                title: "Enabled for Sidebar Right"
                description: "Show parallax when sidebarRight opens."
                prefField: "appearance.background.parallax.enableSidebarRight"
            }

            NumberStepper {
                label: "Zoom Amount"
                description: "Adjust the zoom of the parallax effect."
                prefField: "appearance.background.parallax.zoom"
                step: 0.1
                minimum: 1.10
                maximum: 2
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Metrics.chronoDuration(400)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animation.curves.standard
    }
}
