import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.modules.functions
import qs.services
import qs.modules.interface.lockscreen
import qs.modules.components

PanelWindow {
    id: powermenu

    readonly property bool menuOpen: Config.initialized && Globals.visiblility.powermenu
    property int selectedIndex: 0

    function closeMenu() {
        Globals.visiblility.powermenu = false;
    }

    function togglepowermenu() {
        Globals.visiblility.powermenu = !Globals.visiblility.powermenu;
    }

    onVisibleChanged: {
        if (visible)
            selectedIndex = 0;
    }

    visible: menuOpen
    focusable: menuOpen
    aboveWindows: true
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "nucleus:powermenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: menuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    HyprlandFocusGrab {
        id: grab
        active: Compositor.require("hyprland")
        windows: [powermenu]
    }

    FocusScope {
        id: menuScope
        property var buttons: [powerButton, rebootButton, lockButton, sleepButton, logoutButton]

        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                powermenu.closeMenu();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                powermenu.selectedIndex = (powermenu.selectedIndex + menuScope.buttons.length - 1) % menuScope.buttons.length;
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                powermenu.selectedIndex = (powermenu.selectedIndex + 1) % menuScope.buttons.length;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                const selectedButton = menuScope.buttons[powermenu.selectedIndex];
                if (selectedButton)
                    selectedButton.clicked();
                event.accepted = true;
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Metrics.margin(26)
            width: actionRow.implicitWidth + Metrics.margin(28)
            height: actionRow.implicitHeight + Metrics.margin(28)

            Rectangle {
                anchors.fill: parent
                radius: Metrics.radius("xlarge") + 24
                color: Qt.alpha(Appearance.m3colors.m3surfaceContainerLowest, 0.97)
                border.width: 2
                border.color: Qt.alpha(Appearance.m3colors.m3primary, 0.95)
            }

            RowLayout {
                id: actionRow
                anchors.centerIn: parent
                spacing: Metrics.spacing(22)

                PowerMenuButton {
                    id: powerButton
                    buttonIcon: "power_settings_new"
                    tooltipText: "Power off"
                    selected: powermenu.selectedIndex === 0
                    onClicked: {
                        Quickshell.execDetached(["poweroff"]);
                        powermenu.closeMenu();
                    }
                }

                PowerMenuButton {
                    id: rebootButton
                    buttonIcon: "restart_alt"
                    tooltipText: "Reboot"
                    selected: powermenu.selectedIndex === 1
                    onClicked: {
                        Quickshell.execDetached(["reboot"]);
                        powermenu.closeMenu();
                    }
                }

                PowerMenuButton {
                    id: lockButton
                    buttonIcon: "lock"
                    tooltipText: "Lock"
                    selected: powermenu.selectedIndex === 2
                    onClicked: {
                        Quickshell.execDetached(["qs", "-c", "nucleus-shell", "ipc", "call", "lockscreen", "lock"]);
                        powermenu.closeMenu();
                    }
                }

                PowerMenuButton {
                    id: sleepButton
                    buttonIcon: "sleep"
                    tooltipText: "Suspend"
                    selected: powermenu.selectedIndex === 3
                    onClicked: {
                        Quickshell.execDetached(["systemctl", "suspend"]);
                        powermenu.closeMenu();
                    }
                }

                PowerMenuButton {
                    id: logoutButton
                    buttonIcon: "logout"
                    tooltipText: "Logout"
                    selected: powermenu.selectedIndex === 4
                    onClicked: {
                        Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                        powermenu.closeMenu();
                    }
                }
            }
        }
    }

    IpcHandler {
        function toggle() {
            togglepowermenu();
        }

        target: "powermenu"
    }

    component PowerMenuButton: Item {
        property string buttonIcon
        property bool selected: false
        property string tooltipText: ""

        signal clicked

        width: 106
        height: 106
        property color boxColor: mouseArea.pressed ? Qt.alpha(Appearance.m3colors.m3primaryContainer, 0.42) : selected ? Qt.alpha(Appearance.m3colors.m3surfaceContainerHighest, 0.2) : hover.hovered ? Qt.alpha(Appearance.m3colors.m3surfaceContainerHighest, 0.1) : "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Metrics.radius("xlarge") + 14
            color: boxColor
            border.width: selected ? 2 : 1
            border.color: selected ? Qt.alpha(Appearance.m3colors.m3primary, 0.95) : Qt.alpha(Appearance.m3colors.m3outlineVariant, hover.hovered ? 0.5 : 0.24)

            Behavior on color {
                ColorAnimation {
                    duration: Metrics.chronoDuration("small") / 2
                    easing.type: Appearance.animation.easing
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Metrics.chronoDuration("small") / 2
                    easing.type: Appearance.animation.easing
                }
            }

            Behavior on border.width {
                NumberAnimation {
                    duration: Metrics.chronoDuration("small") / 2
                    easing.type: Appearance.animation.easing
                }
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            icon: buttonIcon
            iconSize: Metrics.iconSize(40)
            color: selected ? Qt.alpha(Appearance.m3colors.m3primary, 0.95) : Appearance.m3colors.m3onSurface

            Behavior on color {
                ColorAnimation {
                    duration: Metrics.chronoDuration("small") / 2
                    easing.type: Appearance.animation.easing
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        HoverHandler {
            id: hover
            enabled: tooltipText !== ""
        }

        LazyLoader {
            active: tooltipText !== ""

            StyledPopout {
                hoverTarget: hover
                hoverDelay: Metrics.chronoDuration(500)

                Component {
                    StyledText {
                        text: tooltipText
                    }
                }
            }
        }
    }
}
