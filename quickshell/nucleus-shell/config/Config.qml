pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property string secretsFilePath: Quickshell.env("HOME") + "/.config/secrets.env"
    property alias runtime: configOptionsJsonAdapter
    readonly property string secretsApiKey: {
        const names = ["OPENROUTER_API_KEY", "OPENROUTER_KEY", "OPENAI_KEY"];
        for (let i = 0; i < names.length; i++) {
            const value = root.readSecretValue(names[i]);
            if (value !== "")
                return value;
        }
        return "";
    }
    readonly property string intelligenceApiKey:
        Quickshell.env("OPENROUTER_API_KEY")
        || Quickshell.env("OPENROUTER_KEY")
        || Quickshell.env("OPENAI_KEY")
        || root.secretsApiKey
        || ""
    property bool initialized: false
    property int readWriteDelay: 50
    property bool blockWrites: false

    function readSecretValue(name) {
        const raw = secretsFileView.text();
        if (!raw || raw === "")
            return "";

        const pattern = new RegExp("^\\s*(?:export\\s+)?" + name + "\\s*=\\s*(.*)\\s*$", "m");
        const match = raw.match(pattern);
        if (!match || !match[1])
            return "";

        let value = match[1].trim();
        if ((value.startsWith("\"") && value.endsWith("\"")) ||
            (value.startsWith("'") && value.endsWith("'"))) {
            value = value.slice(1, -1);
        }
        return value;
    }

    function updateKey(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.runtime;
        if (!obj) {
            console.warn("Config.updateKey: adapter not available for key", nestedKey);
            return;
        }

        for (let i = 0; i < keys.length - 1; ++i) {
            let k = keys[i];
            if (obj[k] === undefined || obj[k] === null || typeof obj[k] !== "object") {
                obj[k] = {};  // Use Plain JS for serialization
            }
            obj = obj[k];
            if (!obj) {
                console.warn("Config.updateKey: failed to resolve", k);
                return;
            }
        }

        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || (!isNaN(Number(trimmed)) && trimmed !== "")) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        obj[keys[keys.length - 1]] = convertedValue;
        configFileView.adapterUpdated();
    }

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: configFileView.reload()
    }
    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: configFileView.writeAdapter()
    }

    Timer {
        // Used to output all log/debug to the terminal
        interval: 1200
        running: true
        repeat: false
        onTriggered: {
            console.log("Detected Compositor:", Compositor.detectedCompositor);
        }
    }

    FileView {
        id: secretsFileView
        path: root.secretsFilePath
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        blockWrites: root.blockWrites
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: {
            root.initialized = true;
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: configOptionsJsonAdapter
            property var monitors: ({}) // per-monitor configuration for bars and wallpapers

            property JsonObject appearance: JsonObject {
                property string theme: "dark"
                property bool tintIcons: false
                property JsonObject animations: JsonObject {
                    property bool enabled: true
                    property double durationScale: 1
                }
                property JsonObject transparency: JsonObject {
                    property bool enabled: false
                    property double alpha: 0.2
                }
                property JsonObject rounding: JsonObject {
                    property double factor: 1
                }
                property JsonObject font: JsonObject {
                    property double scale: 1
                    property JsonObject families: JsonObject {
                        property string main: "JetBrains Mono"
                        property string title: "Gabarito"
                        property string materialIcons: "Material Symbols Rounded"
                        property string nerdFonts: "JetBrains Mono NF"
                        property string monospace: "JetBrains Mono NF"
                        property string reading: "Readex Pro"
                        property string expressive: "Space Grotesk"
                    }
                }
                property JsonObject colors: JsonObject {
                    property string scheme: "catppuccin-lavender"
                    property string matugenScheme: "scheme-neutral"
                    property bool autogenerated: true
                    property bool runMatugenUserWide: false
                    property JsonObject accents: JsonObject {
                        property string primary: "default"
                        property string secondary: "default"
                        property string tertiary: "default"
                    }
                }
                property JsonObject background: JsonObject {
                    property bool enabled: true
                    property url defaultPath: Directories.defaultsPath + "/default.jpg"
                    property string fillMode: "cover"
                    property JsonObject parallax: JsonObject {
                        property bool enabled: true
                        property bool enableSidebarLeft: true
                        property bool enableSidebarRight: true
                        property real zoom: 1.10
                    }
                }
            }

            property JsonObject misc: JsonObject {
                property url pfp: Quickshell.env("HOME") + "/.face.icon"
                property bool useMergedSidebarLayout: false // use merged sidebar layout when bar is merged
                property JsonObject intelligence: JsonObject {
                    property bool enabled: true
                }
            }

            property JsonObject notifications: JsonObject {
                property bool enabled: true
                property bool doNotDisturb: false
                property string position: "center"
            }
            property JsonObject shell: JsonObject {
                property string version: "0.7.7"
                property string qsVersion: "0.0.0"
            }
            property JsonObject overlays: JsonObject {
                property bool enabled: true
                property bool volumeOverlayEnabled: true
                property string volumeOverlayPosition: "top"
            }
            property JsonObject launcher: JsonObject {
                property bool fuzzySearchEnabled: true
                property string webSearchEngine: "google"
            }
            property JsonObject bar: JsonObject {
                property string position: "top"
                property bool enabled: true
                property bool merged: false
                property bool floating: false
                property bool gothCorners: true
                property int radius: Appearance.rounding.large
                property int margins: Appearance.margin.normal
                property int density: 50
                property JsonObject modules: JsonObject {
                    property color paddingColor: Appearance.m3colors.m3surfaceContainer
                    property int radius: Appearance.rounding.normal
                    property int height: 34
                    property JsonObject sidebars: JsonObject {
                        property bool leftSidebarToggleEnabled: true
                        property bool rightSidebarToggleEnabled: true
                    }
                    property JsonObject launcher: JsonObject {
                        property bool enabled: true
                    }
                    property JsonObject workspaces: JsonObject {
                        property bool enabled: true
                    }
                    property JsonObject volume: JsonObject {
                        property bool enabled: true
                    }
                    property JsonObject clock: JsonObject {
                        property bool enabled: true
                    }
                    property JsonObject mediaPlayer: JsonObject {
                        property bool enabled: true
                    }
                    property JsonObject systemUsage: JsonObject {
                        property bool enabled: true
                        property bool cpuStatsEnabled: true
                        property bool memoryStatsEnabled: true
                        property bool tempStatsEnabled: true
                    }
                }
            }
        }
    }
}
