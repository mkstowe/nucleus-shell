pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Wayland
import qs.config
import qs.services
import qs.services as ShellServices
import qs.modules.components

Scope {
    id: root

    readonly property bool active: Globals.states.screenCaptureOpen

    function toSlurpColor(color, alphaSuffix) {
        const raw = String(color);
        if (raw.length === 7)
            return raw + alphaSuffix;
        if (raw.length === 9)
            return "#" + raw.slice(3) + raw.slice(1, 3);
        return raw;
    }

    function openCapture() {
        if (root.active)
            return;
        Globals.states.screenCaptureOpen = true;
    }

    IpcHandler {
        target: "screen"

        function capture() {
            root.openCapture();
        }
    }

    LazyLoader {
        active: root.active

        component: PanelWindow {
            id: win

            property bool closing: false
            property bool processing: false
            property bool windowMode: false
            property string savedPath: ""
            property bool savedSuccess: false
            property string deferredCommand: ""
            property var focusedMonitorInfo: (ShellServices.Hyprland.monitorsInfo ?? []).find(m => m?.focused) ?? null
            property string displayName: screen?.name ?? focusedMonitorInfo?.name ?? ""
            property var monitorInfo: (ShellServices.Hyprland.monitorsInfo ?? []).find(m => m?.name === displayName) ?? focusedMonitorInfo ?? null
            property real logicalMonitorX: monitorInfo?.x ?? 0
            property real logicalMonitorY: monitorInfo?.y ?? 0
            property string slurpBackgroundColor: root.toSlurpColor("#000000", "66")
            property string slurpBorderColor: root.toSlurpColor(Appearance.m3colors.m3primary, "ff")
            property string slurpSelectionColor: root.toSlurpColor(Appearance.m3colors.m3primary, "22")
            property string slurpBoxColor: root.toSlurpColor(Appearance.m3colors.m3surface, "ee")
            property string slurpFontFamily: Config.runtime.appearance.font.families.main

            color: "transparent"
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "nucleus:screencapture"

            function close() {
                if (closing)
                    return;
                closing = true;
                closeAnim.start();
            }

            function captureFullscreen() {
                win.processing = true;
                const ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
                win.savedPath = Quickshell.env("HOME") + "/Pictures/screenshots/screenshot_" + ts + ".png";
                win.deferredCommand = "sleep 0.1 && " + "grim -o '" + win.displayName + "' '" + win.savedPath + "'" + " && wl-copy --type image/png < '" + win.savedPath + "'";
                win.savedSuccess = true;
                win.close();
            }

            function captureWindow(rect) {
                win.processing = true;
                const ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
                win.savedPath = Quickshell.env("HOME") + "/Pictures/screenshots/screenshot_" + ts + "_window.png";
                win.deferredCommand = "sleep 0.1 && " + "grim -g '" + Math.floor(rect.x) + "," + Math.floor(rect.y) + " " + Math.floor(rect.width) + "x" + Math.floor(rect.height) + "' '" + win.savedPath + "'" + " && wl-copy --type image/png < '" + win.savedPath + "'";
                win.savedSuccess = true;
                win.close();
            }

            function captureRegion() {
                win.processing = true;
                const ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
                win.savedPath = Quickshell.env("HOME") + "/Pictures/screenshots/screenshot_" + ts + "_region.png";
                win.deferredCommand = "sleep 0.1 && " + "selection=$(slurp -d" + " -b '" + win.slurpBackgroundColor + "'" + " -c '" + win.slurpBorderColor + "'" + " -s '" + win.slurpSelectionColor + "'" + " -B '" + win.slurpBoxColor + "'" + " -F '" + win.slurpFontFamily + "'" + " -w 2) && [ -n \"$selection\" ] && " + "grim -g \"$selection\" '" + win.savedPath + "'" + " && wl-copy --type image/png < '" + win.savedPath + "'";
                win.savedSuccess = true;
                win.close();
            }

            Item {
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: win.close()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_F) {
                        win.captureFullscreen();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_R) {
                        win.captureRegion();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_W) {
                        win.windowMode = !win.windowMode;
                        event.accepted = true;
                    }
                }

                Image {
                    id: bg
                    anchors.fill: parent
                    source: Config.runtime.appearance.background.path
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0
                    scale: 1

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 64
                        brightness: -0.1
                    }

                    onStatusChanged: {
                        if (status === Image.Ready)
                            fadeIn.start();
                    }

                    NumberAnimation on opacity {
                        id: fadeIn
                        to: 1
                        duration: Metrics.chronoDuration("normal")
                        easing.type: Appearance.animation.easing
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !win.windowMode

                    onPressed: mouse => {
                        mouse.accepted = true;
                        win.captureRegion();
                    }
                }

                Repeater {
                    model: {
                        if (!win.windowMode)
                            return [];

                        const ws = Hyprland.focusedMonitor?.activeWorkspace;
                        return ws?.toplevels ? ws.toplevels.values : [];
                    }

                    delegate: Item {
                        required property var modelData
                        property var w: modelData?.lastIpcObject

                        visible: w?.at && w?.size
                        x: visible ? w.at[0] - win.logicalMonitorX : 0
                        y: visible ? w.at[1] - win.logicalMonitorY : 0
                        width: visible ? w.size[0] : 0
                        height: visible ? w.size[1] : 0
                        z: hover.containsMouse ? 1000 : 100

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Appearance.m3colors.m3primary
                            border.width: hover.containsMouse ? 3 : 0
                            radius: Metrics.radius(8)

                            Behavior on border.width {
                                NumberAnimation {
                                    duration: Metrics.chronoDuration(150)
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Appearance.m3colors.m3primary
                            opacity: hover.containsMouse ? 0.15 : 0
                            radius: Metrics.radius(8)

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Metrics.chronoDuration(150)
                                }
                            }
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                win.captureWindow(Qt.rect(w.at[0], w.at[1], w.size[0], w.size[1]));
                            }
                        }
                    }
                }

                ParallelAnimation {
                    id: closeAnim

                    NumberAnimation {
                        target: bg
                        property: "scale"
                        to: bg.scale - 0.05
                        duration: Metrics.chronoDuration("normal")
                        easing.type: Appearance.animation.easing
                    }

                    onFinished: {
                        if (win.deferredCommand !== "") {
                            Quickshell.execDetached({
                                command: ["sh", "-lc", win.deferredCommand]
                            });
                            win.deferredCommand = "";
                        }

                        Globals.states.screenCaptureOpen = false;
                        if (win.savedSuccess) {
                            Quickshell.execDetached({
                                command: ["notify-send", "Screenshot saved", win.savedPath.split("/").pop() + " (copied)"]
                            });
                        } else if (win.savedPath !== "") {
                            Quickshell.execDetached({
                                command: ["notify-send", "Screenshot failed", "Could not save"]
                            });
                        }
                    }
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Metrics.margin(30)
                width: row.width + 20
                height: row.height + 20

                Rectangle {
                    anchors.fill: parent
                    color: Appearance.m3colors.m3surface
                    radius: Metrics.radius("large")
                }

                RowLayout {
                    id: row
                    anchors.centerIn: parent

                    StyledButton {
                        icon: "fullscreen"
                        text: "Full screen"
                        tooltipText: "Capture the whole screen [F]"
                        onClicked: win.captureFullscreen()
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        width: 2
                        color: Appearance.m3colors.m3onSurfaceVariant
                        opacity: 0.2
                    }

                    StyledButton {
                        icon: "screenshot_region"
                        text: "Region"
                        tooltipText: "Select a region [R]"
                        onClicked: win.captureRegion()
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        width: 2
                        color: Appearance.m3colors.m3onSurfaceVariant
                        opacity: 0.2
                    }

                    StyledButton {
                        icon: "window"
                        checkable: true
                        checked: win.windowMode
                        text: "Window"
                        tooltipText: "Hover and click a window [W]"
                        onClicked: win.windowMode = !win.windowMode
                    }

                    StyledButton {
                        secondary: true
                        icon: "close"
                        tooltipText: "Exit [Escape]"
                        onClicked: win.close()
                    }
                }
            }

            HyprlandFocusGrab {
                id: grab
                windows: [win]
            }

            onVisibleChanged: {
                if (visible)
                    grab.active = true;
            }

            Connections {
                target: grab

                function onActiveChanged() {
                    if (!grab.active && !win.closing)
                        win.close();
                }
            }
        }
    }
}
