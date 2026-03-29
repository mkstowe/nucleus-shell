pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var roleKeys: ["primary", "secondary", "tertiary"]

    function capitalize(label) {
        if (!label || label.length === 0)
            return ""
        return label.charAt(0).toUpperCase() + label.slice(1)
    }

    function availableOptions(accentData) {
        const colors = accentData?.colors
        if (colors)
            return ["default"].concat(Object.keys(colors))

        return ["default", "primary", "secondary", "tertiary"]
    }

    function normalizeSelection(selection, options) {
        if (!selection || selection === "")
            return "default"
        return options.indexOf(selection) >= 0 ? selection : "default"
    }

    function extractRoleFamily(rawColors, role) {
        return {
            color: rawColors[role],
            onColor: rawColors["on_" + role],
            container: rawColors[role + "_container"],
            onContainer: rawColors["on_" + role + "_container"],
            fixed: rawColors[role + "_fixed"],
            fixedDim: rawColors[role + "_fixed_dim"],
            onFixed: rawColors["on_" + role + "_fixed"],
            onFixedVariant: rawColors["on_" + role + "_fixed_variant"]
        }
    }

    function resolveAccentFamily(accentData, selection) {
        const entry = accentData?.colors?.[selection]
        if (!entry)
            return null

        return {
            color: entry.color,
            onColor: accentData.defaults.onColor,
            container: entry.container,
            onContainer: accentData.defaults.onContainer,
            fixed: entry.fixed || entry.color,
            fixedDim: entry.fixedDim || entry.container,
            onFixed: accentData.defaults.onFixed,
            onFixedVariant: accentData.defaults.onFixedVariant
        }
    }

    function resolveFamily(accentData, selection, rawColors, targetRole) {
        if (!selection || selection === "default")
            return extractRoleFamily(rawColors, targetRole)

        const accentFamily = resolveAccentFamily(accentData, selection)
        if (accentFamily)
            return accentFamily

        if (roleKeys.indexOf(selection) >= 0)
            return extractRoleFamily(rawColors, selection)

        return extractRoleFamily(rawColors, targetRole)
    }
}
