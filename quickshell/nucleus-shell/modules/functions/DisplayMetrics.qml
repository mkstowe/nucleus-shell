pragma Singleton
import Quickshell
import QtQuick
import qs.services

Singleton {
    // Prefer Compositor scales because compositor-reported scaling can differ from raw output size.
    function scaledWidth(ratio) {
        return Compositor.screenW * ratio / Compositor.screenScale
    }

    function scaledHeight(ratio) {
        return Compositor.screenH * ratio / Compositor.screenScale
    }
}
