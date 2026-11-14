pragma Singleton

import QtQml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {
    id: root

    property var entries: []
    property var openWindows: ({})
    property var windowKeys: []

    // Window addresses we've already asked Hyprland for client info (pid) about,
    // so a window that never reports a pid can't cause a refresh loop.
    property var pidRequested: ({})

    Component.onCompleted: {
        updateEntries()
        updateOpenWindows()
    }

    // Update desktop entries list when changed
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            updateEntries()
        }
    }

    // update open windows when toplevel change is detected
    Connections {
        target: ToplevelManager.toplevels
        function onValuesChanged() {
            updateTimer.restart()
        }
    }

    // Re-resolve window icons when the resolver learns something new: desktop
    // entries finished loading (they're empty at startup) or a pid hint arrived.
    Connections {
        target: IconResolver
        function onRevisionChanged() {
            updateTimer.restart()
        }
    }

    // Some apps (notably Electron ones) map their window before setting their
    // app id, or change it later. Regroup / re-resolve when that happens.
    Instantiator {
        model: ToplevelManager.toplevels
        delegate: Connections {
            required property var modelData
            target: modelData
            function onAppIdChanged() {
                updateTimer.restart()
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 100
        onTriggered: {
            updateOpenWindows()
        }
    }

    // Hyprland's client info (which carries the pid) is fetched on request;
    // give it a moment to arrive, then resolve again with pids available.
    Timer {
        id: pidRetryTimer
        interval: 300
        onTriggered: {
            updateOpenWindows()
        }
    }
    
    // Updates desktop entries and filters by the passed string
    function updateEntries(filterString) {
        var apps = DesktopEntries.applications.values.slice()

        // Remove duplicate entries(DUplicates would get added sometimes after installing a new package)
        var seen = new Map()
        apps = apps.filter(app => {
            var key = app.id
            if(seen.has(key)) {
                return false
            }
            seen.set(key, true)
            return true
        })

        if (filterString && filterString.length > 0) {
            apps = apps.filter(app => 
                app.name.toLowerCase().includes(filterString.toLowerCase())
            )
        }

        entries = apps.sort((a, b) => a.name.localeCompare(b.name))
    }

    // Updates the global dictionary with information about the open Hyprland windows and their associated applications
    // Rebuilt from scratch every time and reassigned (not mutated in place) so
    // bindings like `openWindows[key]` in the taskbar actually update. Icons are
    // re-resolved every pass too: they can change once desktop entries load,
    // a window's app id changes, or its process identity is known.
    function updateOpenWindows(){
        var windows = {}
        var livePids = []
        var needPids = false
        var requested = Object.assign({}, pidRequested)

        Hyprland.toplevels.values.filter(w => w.wayland).forEach(w => {
            var appId = String(w.wayland.appId || "")
            var pid = w.lastIpcObject && w.lastIpcObject.pid ? String(w.lastIpcObject.pid) : ""

            if (pid) {
                livePids.push(pid)
            } else if (!requested[w.address]) {
                requested[w.address] = true
                needPids = true
            }

            if (!windows[appId]) {
                windows[appId] = {
                    id: appId, // The wayland app id of the window
                    addresses: [],
                    iconPath: IconResolver.iconForApp(appId, pid)
                }
            }
            windows[appId].addresses.push(w.address)
        })

        // Forget bookkeeping for windows / processes that are gone.
        var liveAddresses = Hyprland.toplevels.values.map(w => w.address)
        for (var addr in requested) {
            if (liveAddresses.indexOf(addr) === -1) delete requested[addr]
        }
        pidRequested = requested
        IconResolver.prunePids(livePids)

        openWindows = windows
        // Only reassign the key list when it actually changed, otherwise the
        // taskbar ListView would rebuild every button on each re-resolve.
        var keys = Object.keys(windows)
        if (keys.join("\n") !== windowKeys.join("\n")) windowKeys = keys

        if (needPids) {
            Hyprland.refreshToplevels()
            pidRetryTimer.restart()
        }
    }
}