pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Singleton {
    id: root

    // compositor stuff
    property string detectedCompositor: ""
    
    readonly property var backend: detectedCompositor === "hyprland" ? Hyprland : null

    function detectCompositor() {
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) {
            detectedCompositor = "hyprland"
            return
        }

        const sessionInfo = `${Quickshell.env("XDG_CURRENT_DESKTOP")} ${Quickshell.env("XDG_SESSION_DESKTOP")}`.trim().toLowerCase()
        if (sessionInfo.includes("hyprland"))
            detectedCompositor = "hyprland"
    }

    function require(compositors) { // This function can be effectively used to detect check requirements for a feature (also supports multiple compositors)
        if (Array.isArray(compositors)) {
            return compositors.includes(detectedCompositor);
        }
        return compositors === detectedCompositor;
    }

    // Unified api
    property string title: backend?.title ?? ""
    property bool isFullscreen: backend?.isFullscreen ?? false
    property string layout: backend?.layout ?? "Tiled"
    property int focusedWorkspaceId: backend?.focusedWorkspaceId ?? 1
    property var workspaces: backend?.workspaces ?? []
    property var windowList: backend?.windowList ?? []
    property bool initialized: backend?.initialized ?? true
    property int workspaceCount: backend?.workspaceCount ?? 0
    property real screenW: backend?.screenW ?? 0
    property real screenH: backend?.screenH ?? 0
    property real screenScale: backend?.screenScale ?? 1
    readonly property Toplevel activeToplevel: ToplevelManager.activeToplevel

    function changeWorkspace(id) {
        backend?.changeWorkspace?.(id)
    }

    function changeWorkspaceRelative(delta) {
        backend?.changeWorkspaceRelative?.(delta)
    }

    function isWorkspaceOccupied(id) {
        return backend?.isWorkspaceOccupied?.(id) ?? false
    }

    function focusedWindowForWorkspace(id) {
        return backend?.focusedWindowForWorkspace?.(id) ?? null
    }

    // process to detect compositor
    Component.onCompleted: detectCompositor()

    signal stateChanged()

    Connections {
        target: backend
        function onStateChanged() {
            root.stateChanged()
        }
    }

}
