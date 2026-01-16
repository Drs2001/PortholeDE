pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {
    id: root

    property var entries: []
    property var openWindows: ({})
    property var windowKeys: []
    
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

    Timer {
        id: updateTimer
        interval: 100
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
    function updateOpenWindows(){  
        var currentAppIds = new Set()

        // Refresh addresses
        Object.keys(openWindows).forEach(appId => {
            openWindows[appId].addresses = []
        })

        Hyprland.toplevels.values.filter(w => w.wayland).forEach(w => {
            var appId = w.wayland.appId
            var application = DesktopEntries.heuristicLookup(appId)
            currentAppIds.add(appId)

            // Check if we found something with the heuristic look up and if not check if its  chrome webapp
            if(!application){
                if(appId.includes("chrome")){
                    application = DesktopEntries.heuristicLookup("chromium")
                }
            }
            
            // We attempt to get the icon path here as not all appIds corrospond to applicaitons, so we want to make sure some icon is displayed
            var iconPath = getIcon(appId, application)

            if(!openWindows[appId]){
                openWindows[appId] = {
                    id: String(appId), // The wayland app id of the window
                    addresses: [],
                    iconPath: String(iconPath) // The icon path for the window
                }

                openWindows[appId].addresses.push(w.address)
            }
            else {
                openWindows[appId].addresses.push(w.address)
            }
        })

        // Remove appIds that are no longer in toplevels
        Object.keys(openWindows).forEach(appId => {
            if(!currentAppIds.has(appId)) {
                delete openWindows[appId]
            }
        })

        windowKeys = Object.keys(openWindows)
    }

    function getIcon(appId, application) {
        var iconPath = ""
        if(application){
            iconPath = Quickshell.iconPath(application.icon, true)
        }
        else {
            iconPath = Quickshell.iconPath(appId, true)
        }

        if(iconPath == ""){
            if(appId.includes("steam")){
                iconPath = Quickshell.iconPath(appId.replace("app", "icon"), true)
            }
            
            if(iconPath == ""){
                iconPath = Quickshell.iconPath(findIconFallback(appId), true)
            }

            if(iconPath == ""){
                iconPath = Quickshell.iconPath("application-default-icon", true)
            }
        }

        return iconPath
    }

    function findIconFallback(appId){
        // 2. Convert to lowercase for case-insensitive matching
        let searchId = appId.toLowerCase();
        
        // 3. Remove version numbers and common suffixes
        // Match patterns like "1.21.1", "v2.0", etc.
        searchId = searchId.replace(/[_\s-]*(v?\d+\.)*\d+(\.\d+)*[_\s-]*/g, '');
        
        // 4. Remove common special characters and cleanup
        searchId = searchId.replace(/[*&$@#!()[\]{}]/g, '');
        
        // 5. Remove common suffixes
        searchId = searchId.replace(/[_\s-]*(beta|alpha|stable|dev|nightly|git)$/i, '');
        
        // 6. Split on common separators and take first significant part
        let parts = searchId.split(/[_\s-]+/);
        searchId = parts[0] || searchId;
        
        // 7. Try to find icon with this cleaned name
        return searchId;
    }
}