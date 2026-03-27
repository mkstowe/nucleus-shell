pragma Singleton
import QtQuick
import Quickshell
import qs.config

/*

    This service primarily resolves configs for widgets that are customizable per monitor.

*/

Singleton {
    function isObject(value) {
        return value !== null && typeof value === "object" && !Array.isArray(value);
    }

    function mergeObjects(base, override) {
        if (!isObject(base))
            return override;

        let merged = {};

        for (let key in base) {
            const value = base[key];
            merged[key] = isObject(value) ? mergeObjects(value, {}) : value;
        }

        if (!isObject(override))
            return merged;

        for (let key in override) {
            const overrideValue = override[key];
            if (overrideValue === undefined)
                continue;
            merged[key] = isObject(overrideValue) && isObject(merged[key]) ? mergeObjects(merged[key], overrideValue) : overrideValue;
        }

        return merged;
    }

    function bar(displayName) {
        const displays = Config.runtime.monitors;
        const fallback = Config.runtime.bar;
        if (!displays || !displays[displayName] || !displays[displayName].bar || displayName === "")
            return fallback;

        return mergeObjects(fallback, displays[displayName].bar);
    }

    function getBarConfigurableHandle(displayName) { // returns prefField string
        const displays = Config.runtime.monitors;

        if (!displays || !displays[displayName] || !displays[displayName].bar || displayName === "")
            return "bar";

        return "monitors." + displayName + ".bar";
    }
}
