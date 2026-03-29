import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland as QsHyprland
import qs.config
import qs.modules.functions
import qs.modules.components
import qs.services

Scope {
    id: root
    property bool wallpaperFailed: false

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: backgroundContainer

            required property var modelData
            property string displayName: modelData.name

            property url wallpaperPath: {
                const displays = Config.runtime.monitors
                const fallback = Config.runtime.appearance.background.defaultPath

                if (!displays)
                    return fallback

                const monitor = displays?.[displayName]
                return monitor?.wallpaper ?? fallback
            }
            property string wallpaperFillMode: Config.runtime.appearance.background.fillMode
            property int imageFillMode: {
                switch (wallpaperFillMode) {
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
            property bool coverMode: wallpaperFillMode === "cover"

            // parallax config
            property bool parallaxEnabled: Config.runtime.appearance.background.parallax.enabled && coverMode
            property real parallaxZoom: Config.runtime.appearance.background.parallax.zoom
            property var monitorWorkspaceIds: Hyprland.workspaceIdsForMonitor(displayName)
            property int workspaceRange: Math.max(1, monitorWorkspaceIds.length)

            // hyprland
            property int activeWorkspaceId: QsHyprland.focusedWorkspace?.id ?? 1

            // wallpaper geometry
            property real wallpaperWidth: bgImg.implicitWidth
            property real wallpaperHeight: bgImg.implicitHeight

            property real wallpaperToScreenRatio: {
                if (wallpaperWidth <= 0 || wallpaperHeight <= 0)
                    return 1
                return Math.min(
                    wallpaperWidth / width,
                    wallpaperHeight / height
                )
            }

            property real effectiveScale: parallaxEnabled ? parallaxZoom : 1

            property real movableXSpace: Math.max(
                0,
                ((wallpaperWidth / wallpaperToScreenRatio * effectiveScale) - width) / 2
            )

            // workspace mapping
            property int lowerWorkspace: Math.floor((activeWorkspaceId - 1) / workspaceRange) * workspaceRange + 1
            property int upperWorkspace: lowerWorkspace + workspaceRange
            property int workspaceSpan: Math.max(1, upperWorkspace - lowerWorkspace)

            property real valueX: {
                if (!parallaxEnabled)
                    return 0.5
                return (activeWorkspaceId - lowerWorkspace) / workspaceSpan
            }

            // sidebar globals
            property bool sidebarLeftOpen: Globals.visiblility.sidebarLeft
                && Config.runtime.appearance.background.parallax.enableSidebarLeft

            property bool sidebarRightOpen: Globals.visiblility.sidebarRight
                && Config.runtime.appearance.background.parallax.enableSidebarRight

            property real sidebarOffset: {
                if (sidebarLeftOpen && !sidebarRightOpen)
                    if (Config.runtime.bar.position === "right")
                        return 0.15
                    else return -0.15
                if (sidebarRightOpen && !sidebarLeftOpen)
                    if (Config.runtime.bar.position === "left")
                        return -0.15
                    else return 0.15
                return 0
            }

            property real effectiveValueX: Math.max(
                0,
                Math.min(
                    1,
                    valueX + sidebarOffset
                )
            )

            // window
            color: (bgImg.status === Image.Error) ? Appearance.colors.colLayer2 : "transparent"
            WlrLayershell.namespace: "nucleus:background"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            screen: modelData
            visible: Config.initialized && Config.runtime.appearance.background.enabled

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            // wallpaper picker
            Process {
                id: wallpaperProc

                command: ["bash", "-c", Directories.scriptsPath + "/interface/changebg.sh"]

                stdout: StdioCollector {
                    onStreamFinished: {
                    const out = text.trim()

                    if (out !== "null" && out.length > 0) {
                        const parts = out.split("|")

                        if (parts.length === 2) {
                            const monitor = parts[0]
                            const wallpaper = parts[1]

                            Config.updateKey(
                                "monitors." + monitor + ".wallpaper",
                                wallpaper
                            )
                        }
                    }

                        if (Config.runtime.appearance.colors.autogenerated) {
                            Quickshell.execDetached([
                                "qs", "ipc",
                                "-p", Quickshell.shellPath("."),
                                "call", "global", "regenColors", screen.name
                            ]);
                        }
                    }
                }
            }

            // wallpaper
            Item {
                anchors.fill: parent
                clip: true

                StyledImage {
                    id: bgImg

                    visible: status === Image.Ready
                    smooth: false
                    cache: false
                    fillMode: imageFillMode
                    source: wallpaperPath + "?t=" + Date.now()

                    anchors.fill: coverMode ? undefined : parent
                    width: coverMode ? wallpaperWidth / wallpaperToScreenRatio * effectiveScale : parent.width
                    height: coverMode ? wallpaperHeight / wallpaperToScreenRatio * effectiveScale : parent.height

                    x: coverMode ? -movableXSpace - (effectiveValueX - 0.5) * 2 * movableXSpace : 0
                    y: 0

                    Behavior on x {
                        enabled: coverMode
                        NumberAnimation {
                            duration: Metrics.chronoDuration(600)
                            easing.type: Easing.OutCubic
                        }
                    }

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            backgroundContainer.wallpaperWidth = implicitWidth
                            backgroundContainer.wallpaperHeight = implicitHeight
                        }
                        root.wallpaperFailed = status === Image.Error
                    }
                }

                MouseArea {
                    id: widgetCanvas
                    anchors.fill: parent
                }

                // error ui
                Item {
                    anchors.centerIn: parent
                    visible: bgImg.status === Image.Error

                    Rectangle {
                        width: 550
                        height: 400
                        radius: Appearance.rounding.windowRounding
                        color: "transparent"
                        anchors.centerIn: parent

                        ColumnLayout {
                            anchors.centerIn: parent
                            anchors.margins: Metrics.margin("normal")
                            spacing: Metrics.margin("small")

                            MaterialSymbol {
                                text: "wallpaper"
                                font.pixelSize: Metrics.fontSize("wildass")
                                color: Appearance.colors.colOnLayer2
                                Layout.alignment: Qt.AlignHCenter
                            }

                            StyledText {
                                text: "Wallpaper Missing"
                                font.pixelSize: Metrics.fontSize("hugeass")
                                font.bold: true
                                color: Appearance.colors.colOnLayer2
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                            }

                            StyledText {
                                text: "Seems like you haven't set a wallpaper yet."
                                font.pixelSize: Metrics.fontSize("small")
                                color: Appearance.colors.colSubtext
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Item { Layout.fillHeight: true }

                            StyledButton {
                                text: "Set wallpaper"
                                icon: "wallpaper"
                                secondary: true
                                radius: Metrics.radius("large")
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: wallpaperProc.running = true
                            }
                        }
                    }
                }
            }

            IpcHandler {
                target: "background"

                function change() {
                    wallpaperProc.running = true
                }
            }
        }
    }

}
