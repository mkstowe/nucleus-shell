import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import Quickshell.Wayland
import qs.config
import qs.modules.functions
import qs.modules.components
import qs.services

Rectangle {
    id: root

    required property LockContext context
    property string displayName: screen?.name ?? ""

    color: "transparent"

    Image {
        anchors.fill: parent
        z: -1
        property string previewImg: {
            const displays = Config.runtime.monitors
            const fallback = Config.runtime.appearance.background.defaultPath

            if (!displays)
                return fallback

                const monitor = displays?.[displayName]
                return monitor?.wallpaper ?? fallback
            }

        source: previewImg + "?t=" + Date.now()
    }

    RowLayout {
        spacing: Metrics.spacing(20)

        anchors {
            top: parent.top
            right: parent.right
            topMargin: Metrics.spacing(20)
            rightMargin: Metrics.spacing(30)
        }

        MaterialSymbol {
            id: themeIcon

            fill: 1
            icon: Config.runtime.appearance.theme === "light" ? "light_mode" : "dark_mode"
            iconSize: Metrics.fontSize("hugeass")
        }

        MaterialSymbol {
            id: wifi

            icon: Network.icon
            iconSize: Metrics.fontSize("hugeass")
        }

        MaterialSymbol {
            id: btIcon

            icon: Bluetooth.icon
            iconSize: Metrics.fontSize("hugeass")
        }

        StyledText {
            id: keyboardLayoutIcon

            text: SystemDetails.keyboardLayout
            font.pixelSize: Metrics.fontSize(Appearance.font.size.huge - 4)
        }

    }

    ColumnLayout {
        // Commenting this will make the password entry visible on all monitors.
        visible: Window.active

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Metrics.margin(20)
        }

        RowLayout {
            StyledTextField {
                id: passwordBox

                implicitWidth: 300
                padding: Metrics.padding(10)
                placeholder: root.context.showFailure ? "Incorrect Password" : "Enter Password"
                focus: true
                enabled: !root.context.unlockInProgress
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                // Update the text in the context when the text in the box changes.
                onTextChanged: root.context.currentText = this.text
                // Try to unlock when enter is pressed.
                onAccepted: root.context.tryUnlock()

                // Update the text in the box to match the text in the context.
                // This makes sure multiple monitors have the same text.
                Connections {
                    function onCurrentTextChanged() {
                        passwordBox.text = root.context.currentText;
                    }

                    target: root.context
                }

            }

            StyledButton {
                icon: "chevron_right"
                padding: Metrics.padding(10)
                radius: Metrics.radius("large")
                // don't steal focus from the text box
                focusPolicy: Qt.NoFocus
                enabled: !root.context.unlockInProgress && root.context.currentText !== ""
                onClicked: root.context.tryUnlock()
            }

        }

    }

}
