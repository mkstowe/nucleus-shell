import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls

import qs.modules.components
import qs.modules.functions
import qs.config
import qs.services

PanelWindow {
    id: launcherWindow

    readonly property bool launcherOpen: Globals.visiblility.launcher
    readonly property int launcherWidth: DisplayMetrics.scaledWidth(0.31)
    readonly property int launcherHeight: DisplayMetrics.scaledHeight(0.34)
    readonly property int resultRowHeight: Metrics.margin(60)
    readonly property int resultRowSpacing: Metrics.spacing(10)

    visible: launcherOpen
    focusable: launcherOpen
    aboveWindows: true
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore // why this? idk but it works atleast
    WlrLayershell.keyboardFocus: launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Appearance.m3colors.m3surface, 1)
    }

    FocusScope {
        id: launcher
        property string currentSearch: ""
        property int entryIndex: 0
        property var appList: Apps.list

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -DisplayMetrics.scaledHeight(0.03)
        width: launcherWindow.launcherWidth
        height: launcherWindow.launcherHeight
        focus: true

        function webSearchUrl(query) {
            const engine = (Config.runtime.launcher.webSearchEngine || "").toLowerCase()
            if (engine.startsWith("http"))
                return engine.replace("%s", encodeURIComponent(query))

            const engines = {
                "google": "https://www.google.com/search?q=%s",
                "duckduckgo": "https://duckduckgo.com/?q=%s",
                "brave": "https://search.brave.com/search?q=%s",
                "bing": "https://www.bing.com/search?q=%s",
                "startpage": "https://www.startpage.com/search?q=%s"
            }

            const template = engines[engine] || engines["google"]
            return template.replace("%s", encodeURIComponent(query))
        }

        function defaultQuery(search) {
            const normalized = search.toLowerCase().trim()
            if (normalized === "")
                return Apps.list

            return Apps.list.filter(app => {
                const name = (app.name || "").toLowerCase()
                const comment = (app.comment || "").toLowerCase()
                return name.includes(normalized) || comment.includes(normalized)
            })
        }

        function webSearchEntry(query) {
            return {
                name: `Search the web for "${query}"`,
                execute: () => Quickshell.execDetached(["xdg-open", launcher.webSearchUrl(query)])
            }
        }

        function refreshResults() {
            const query = launcher.currentSearch.trim()
            const results = query === ""
                ? Apps.list
                : (Config.runtime.launcher.fuzzySearchEnabled ? Apps.fuzzyQuery(query) : launcher.defaultQuery(query))

            launcher.appList = results.length > 0 ? results : (query !== "" ? [launcher.webSearchEntry(query)] : [])

            if (launcher.appList.length === 0) {
                launcher.entryIndex = -1
                return
            }

            launcher.entryIndex = Math.max(0, Math.min(launcher.entryIndex, launcher.appList.length - 1))
        }

        Connections {
            target: launcherWindow
            function onLauncherOpenChanged() {
                if (!launcherWindow.launcherOpen) {
                    launcher.currentSearch = ""
                    launcher.entryIndex = 0
                    launcher.appList = Apps.list
                    searchBox.text = ""
                } else {
                    searchBox.forceActiveFocus()
                }
            }
        }

        TextInput {
            id: searchBox
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Metrics.margin(24)
            focus: true
            clip: true

            color: Appearance.m3colors.m3onSurface
            selectedTextColor: Appearance.m3colors.m3onPrimary
            selectionColor: Qt.alpha(Appearance.m3colors.m3primary, 0.35)
            font.pixelSize: Metrics.fontSize(24)
            font.family: Metrics.fontFamily("main")
            verticalAlignment: TextInput.AlignVCenter
            cursorVisible: activeFocus

            onTextChanged: {
                launcher.currentSearch = text
                launcher.entryIndex = 0
                launcher.refreshResults()
            }

            Keys.onDownPressed: {
                if (launcher.appList.length > 0)
                    launcher.entryIndex = Math.min(launcher.entryIndex + 1, launcher.appList.length - 1)
            }
            Keys.onUpPressed: {
                if (launcher.appList.length > 0)
                    launcher.entryIndex = Math.max(launcher.entryIndex - 1, 0)
            }
            Keys.onEscapePressed: Globals.visiblility.launcher = false

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    if (launcher.entryIndex >= 0 && launcher.entryIndex < launcher.appList.length) {
                        launcher.appList[launcher.entryIndex].execute()
                        Globals.visiblility.launcher = false
                    }
                    event.accepted = true
                }
            }
        }

        ScrollView {
            id: resultsView
            anchors.top: searchBox.bottom
            anchors.topMargin: Metrics.margin(32)
            anchors.left: parent.left
            anchors.right: parent.right
            height: (launcherWindow.resultRowHeight * 6) + (launcherWindow.resultRowSpacing * 5)
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: appList
                anchors.fill: parent
                spacing: launcherWindow.resultRowSpacing
                boundsBehavior: Flickable.StopAtBounds
                model: launcher.appList
                currentIndex: launcher.entryIndex

                delegate: AppItem {
                    required property int index
                    entryData: launcher.appList[index]
                    selected: index === launcher.entryIndex
                    parentWidth: appList.width
                }
            }
        }

        StyledText {
            visible: launcher.appList.length === 0
            anchors.top: searchBox.bottom
            anchors.topMargin: Metrics.margin(18)
            anchors.left: searchBox.left
            text: "No applications found"
            color: Qt.alpha(Appearance.m3colors.m3outline, 0.75)
            font.pixelSize: Metrics.fontSize(18)
            animate: false
        }
    }

    IpcHandler {
        function toggle() {
            Globals.visiblility.launcher = !Globals.visiblility.launcher;
        }

        target: "launcher"
    }
    
}
