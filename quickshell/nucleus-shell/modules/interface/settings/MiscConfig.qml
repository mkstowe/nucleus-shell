import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.modules.components
import qs.services

ContentMenu {
    title: "Miscellaneous"
    description: "Configure misc settings."

    ContentCard {
        StyledText {
            text: "Sidebar Layout"
            font.pixelSize: Metrics.fontSize(20)
            font.bold: true
        }

        StyledSwitchOption {
            title: "Merged Layout"
            description: "Use merged layout for sidebars when bar is merged."
            prefField: "misc.useMergedSidebarLayout"
        }
    }

    ContentCard {
        StyledText {
            text: "Intelligence"
            font.pixelSize: Metrics.fontSize(20)
            font.bold: true
        }

        StyledSwitchOption {
            title: "Enabled"
            description: "Enable or disable intelligence."
            prefField: "misc.intelligence.enabled"
        }
    }

    ContentCard {
        StyledText {
            text: "Intelligence Setup"
            font.pixelSize: Metrics.fontSize(20)
            font.bold: true
        }

        StyledText {
            text: Config.intelligenceApiKey !== ""
                ? "Intelligence found an API key from your environment or ~/.config/secrets.env."
                : "Add OPENROUTER_API_KEY, OPENROUTER_KEY, or OPENAI_KEY to ~/.config/secrets.env to enable Intelligence."
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            font.pixelSize: Metrics.fontSize(16)
        }

        Item {
            width: 20
        }

        InfoCard {
            title: "secrets.env"
            description: "Example: export OPENROUTER_KEY=\"...\" in ~/.config/secrets.env, then reload Nucleus."
        }
    }
}
