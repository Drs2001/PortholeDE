pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var desktopPath: Quickshell.env("HOME") + "/Desktop"
    property var desktopIcons: ListModel {}

    // Grid cell size in pixels. gridX/gridY (both in this model and in the DB)
    // are CELL INDICES (column/row), not raw pixel coordinates. DesktopGrid.qml
    // multiplies by these to get the actual on-screen position.
    property int cellWidth: 80
    property int cellHeight: 90

    Connections {
        target: DesktopWatcher

        function onFileAdded(inode, filename){
            console.log("FILE Added: ", inode)
            // We only get inode + filename here, not the file type or its icon,
            // so queue the filename and resolve those in a subprocess (same logic
            // as the boot sync) before inserting a DB row / grid entry.
            enqueueAdd(filename)
        }
        function onFileRemoved(inode, filename){
            console.log("FILE Removed: ", inode)
            // A deleted file can't be stat'd, so the watcher reports inode "0".
            // Fall back to matching by filename and remove the row by its REAL
            // inode, otherwise stale/duplicate DB rows pile up forever.
            var idx = findIndexByInode(inode)
            if (idx === -1) {
                idx = findIndexByName(filename)
            }
            if (idx !== -1) {
                var realInode = desktopIcons.get(idx).inode
                desktopIcons.remove(idx)
                DBInterface.desktopIconEntryRemove(realInode)
            }
        }
        function onFileRenamed(inode, filename){
            console.log("FILE Renamed: ", inode)
            var idx = findIndexByInode(inode)
            if (idx !== -1) {
                desktopIcons.setProperty(idx, "name", filename)
                // Keep the DB name in sync so it survives a restart.
                var e = desktopIcons.get(idx)
                DBInterface.desktopIconEntryUpdate(e.inode, e.name, e.isDir, e.gridX, e.gridY, e.screen, e.iconName)
            }
        }
    }

    // ── Newly-added file handling ────────────────────────────────────────────
    // inotify hands us just a filename, so we resolve type + icon in a subprocess
    // (mirroring the boot sync) and place the file on the grid. Adds are queued
    // and processed one at a time so concurrent creates can't race on free cells.
    property var addQueue: []
    property bool resolving: false

    readonly property string addResolveScript: `
        f="$1"
        [ -e "$f" ] || exit 0
        inode=$(stat -c %i "$f" 2>/dev/null) || exit 0
        name=$(basename "$f")
        if [ -d "$f" ]; then
            echo "$inode|d|$name|folder"
        else
            case "$name" in
                *.desktop)
                    icon=$(grep -m1 '^Icon=' "$f" | cut -d= -f2-)
                    [ -z "$icon" ] && icon="application-x-executable"
                    echo "$inode|f|$name|$icon"
                    ;;
                *)
                    icons=$(gio info -a standard::icon "$f" 2>/dev/null | grep 'standard::icon:' | sed 's/.*standard::icon: //' | tr -d ' ')
                    [ -z "$icons" ] && icons="application-x-generic"
                    echo "$inode|f|$name|$icons"
                    ;;
            esac
        fi
    `

    Process {
        id: addResolver
        stdout: StdioCollector {
            onStreamFinished: {
                // Each resolve emits one line; take the last non-empty one so a
                // reused collector that accumulates output can't corrupt parsing.
                var lines = this.text.trim().split("\n")
                var line = lines[lines.length - 1].trim()
                if (line) {
                    var info = line.split("|")
                    handleResolvedAdd(info[0], info[2], info[1] === "d", info[3])
                }
                resolving = false
                addRestartTimer.restart()
            }
        }
    }

    // Small gap so the finished process is fully torn down before we reuse it.
    Timer {
        id: addRestartTimer
        interval: 10
        repeat: false
        onTriggered: processNextAdd()
    }

    function enqueueAdd(filename) {
        addQueue.push(filename)
        processNextAdd()
    }

    function processNextAdd() {
        if (resolving || addQueue.length === 0) return
        resolving = true
        var filename = addQueue.shift()
        addResolver.command = ["sh", "-c", addResolveScript, "porthole", desktopPath + "/" + filename]
        addResolver.running = true
    }

    // Insert a resolved new file into the DB + model, placed on the first free cell.
    function handleResolvedAdd(inode, name, isDir, iconName) {
        if (findIndexByInode(inode) !== -1) return   // already tracked

        var screenObj = Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        var screen = screenObj ? screenObj.name : ""
        var maxCols = screenObj ? Math.max(1, Math.floor(screenObj.width / cellWidth)) : 10
        var maxRows = screenObj ? Math.max(1, Math.floor(screenObj.height / cellHeight)) : 10

        var cell = findFreeCell(0, 0, screen, maxCols, maxRows, inode)

        DBInterface.desktopIconEntryUpdate(inode, name, isDir, cell.col, cell.row, screen, iconName)

        desktopIcons.append({
            inode: inode,
            name: name,
            isDir: isDir,
            gridX: cell.col,
            gridY: cell.row,
            screen: screen,
            iconName: iconName
        })
    }

    // Walks ~/Desktop and, per entry, resolves an icon-name candidate list:
    //   - directories        -> "folder"
    //   - .desktop launchers  -> the Icon= value from the file
    //   - everything else     -> gio's standard::icon list (MIME-based, e.g.
    //                            "text-plain,text-x-generic,text"), so themed
    //                            per-filetype icons work with generic fallbacks.
    // Output is one "inode|type|filename|iconList" row per entry.
    Process {
        id: dbSync
        running: true
        command: ["sh", "-c",
            `find "${desktopPath}" -mindepth 1 -maxdepth 1 -printf '%i|%y|%f\n' |
            while IFS="|" read -r inode type fname; do
                fpath="${desktopPath}/$fname"
                if [ "$type" = "d" ]; then
                    echo "$inode|d|$fname|folder"
                else
                    case "$fname" in
                        *.desktop)
                            icon=$(grep -m1 '^Icon=' "$fpath" | cut -d= -f2-)
                            [ -z "$icon" ] && icon="application-x-executable"
                            echo "$inode|f|$fname|$icon"
                            ;;
                        *)
                            icons=$(gio info -a standard::icon "$fpath" 2>/dev/null | grep 'standard::icon:' | sed 's/.*standard::icon: //' | tr -d ' ')
                            [ -z "$icons" ] && icons="application-x-generic"
                            echo "$inode|f|$fname|$icons"
                            ;;
                    esac
                fi
            done`
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var folderEntries = this.text.split("\n")
                var defaultScreen = Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""

                var liveInodes = []
                for(const entry of folderEntries) {
                    if(entry){
                        var info = entry.split("|")
                        liveInodes.push(info[0])
                        // -1/-1 marks "not yet placed on the grid". refreshDesktopFromDB()
                        // assigns these a real cell the first time they're loaded.
                        DBInterface.desktopIconEntryDBSync(info[0], info[2], (info[1] == "d"), -1, -1, defaultScreen, info[3])
                    }
                }

                // Drop DB rows for files that no longer exist on disk (deleted
                // while the shell was closed, or leftover from old buggy deletes).
                DBInterface.desktopIconEntryKeepOnly(liveInodes)

                refreshDesktopFromDB()
            }
        }
    }

    function refreshDesktopFromDB() {
        var entries = DBInterface.desktopIconEntryGetAll()

        // Rebuild from scratch so this is safe to call more than once.
        desktopIcons.clear()

        if (!entries) return

        var screenNames = []
        for (var s = 0; s < Quickshell.screens.length; s++) {
            screenNames.push(Quickshell.screens[s].name)
        }
        var defaultScreen = screenNames.length > 0 ? screenNames[0] : ""

        for(var i = 0; i < entries.length; i++) {
            var entry = entries.item(i)
            var screen = entry.screen
            var gridX = entry.gridX
            var gridY = entry.gridY

            // If this row's screen isn't one that's currently connected (monitor
            // renamed/unplugged, or the row was written by the old code that
            // hardcoded a screen name), fall back to the primary screen and
            // force a re-place below.
            if (screenNames.indexOf(screen) === -1) {
                screen = defaultScreen
                gridX = -1
                gridY = -1
            }

            var screenObj = null
            for (var s2 = 0; s2 < Quickshell.screens.length; s2++) {
                if (Quickshell.screens[s2].name === screen) {
                    screenObj = Quickshell.screens[s2]
                    break
                }
            }
            var maxCols = screenObj ? Math.max(1, Math.floor(screenObj.width / cellWidth)) : 10
            var maxRows = screenObj ? Math.max(1, Math.floor(screenObj.height / cellHeight)) : 10

            // Catches the -1 sentinel AND stale leftover values (e.g. old pixel-based
            // coordinates from before grid indices existed) that fall outside the
            // valid cell range for this screen.
            if (gridX < 0 || gridY < 0 || gridX >= maxCols || gridY >= maxRows) {
                var cell = findFreeCell(0, 0, screen, maxCols, maxRows, entry.inode)
                gridX = cell.col
                gridY = cell.row
            }

            if (gridX !== entry.gridX || gridY !== entry.gridY || screen !== entry.screen) {
                DBInterface.desktopIconEntryUpdatePos(entry.inode, entry.name, entry.isDir, gridX, gridY, screen, entry.iconName)
            }

            desktopIcons.append({
                inode: entry.inode,
                name: entry.name,
                // SQLite hands isDir back as a Number (0/1); coerce to a real
                // Bool so the ListModel role type matches the Bool that
                // handleResolvedAdd appends. Mixing the two makes QML reject the
                // assignment and silently drop the value (breaking activateIcon).
                isDir: (entry.isDir == 1),
                gridX: gridX,
                gridY: gridY,
                screen: screen,
                iconName: entry.iconName
            })
        }
    }

    function findIndexByInode(inode) {
        for (var i = 0; i < desktopIcons.count; i++) {
            if (String(desktopIcons.get(i).inode) === String(inode)) return i
        }
        return -1
    }

    function findIndexByName(name) {
        for (var i = 0; i < desktopIcons.count; i++) {
            if (desktopIcons.get(i).name === name) return i
        }
        return -1
    }

    function isOccupied(col, row, screen, excludeInode) {
        for (var i = 0; i < desktopIcons.count; i++) {
            var e = desktopIcons.get(i)
            if (excludeInode !== undefined && String(e.inode) === String(excludeInode)) continue
            if (e.screen === screen && e.gridX === col && e.gridY === row) return true
        }
        return false
    }

    // Finds the nearest free cell to (col, row) on the given screen, scanning
    // outward in expanding square rings so a drop onto an occupied cell settles
    // next to it instead of stacking on top of it.
    function findFreeCell(col, row, screen, maxCols, maxRows, excludeInode) {
        col = Math.max(0, Math.min(col, maxCols - 1))
        row = Math.max(0, Math.min(row, maxRows - 1))

        if (!isOccupied(col, row, screen, excludeInode)) {
            return { col: col, row: row }
        }

        var maxRadius = Math.max(maxCols, maxRows)
        for (var radius = 1; radius <= maxRadius; radius++) {
            for (var dy = -radius; dy <= radius; dy++) {
                for (var dx = -radius; dx <= radius; dx++) {
                    // only test the ring perimeter; interior cells were already checked
                    if (Math.max(Math.abs(dx), Math.abs(dy)) !== radius) continue

                    var c = col + dx
                    var r = row + dy
                    if (c < 0 || c >= maxCols || r < 0 || r >= maxRows) continue
                    if (!isOccupied(c, r, screen, excludeInode)) {
                        return { col: c, row: r }
                    }
                }
            }
        }

        // Grid is completely full: fall back to the originally requested cell
        // (results in an overlap, but avoids silently dropping the icon)
        return { col: col, row: row }
    }

    // pixelX/pixelY are raw drop coordinates within the target screen's grid
    // window. maxCols/maxRows are that screen's grid capacity, computed by
    // DesktopGrid.qml from its own window size (so it's correct per-monitor).
    function updateDesktopIconXY(inode, pixelX, pixelY, screen, maxCols, maxRows) {
        var idx = findIndexByInode(inode)
        if (idx === -1) return

        var col = Math.floor(pixelX / cellWidth)
        var row = Math.floor(pixelY / cellHeight)

        var cell = findFreeCell(col, row, screen, maxCols, maxRows, inode)

        desktopIcons.setProperty(idx, "gridX", cell.col)
        desktopIcons.setProperty(idx, "gridY", cell.row)
        desktopIcons.setProperty(idx, "screen", screen)

        var entry = desktopIcons.get(idx)
        DBInterface.desktopIconEntryUpdatePos(entry.inode, entry.name, entry.isDir, entry.gridX, entry.gridY, entry.screen, entry.iconName)
    }

    // Takes the comma-separated icon-name candidate list stored for an entry
    // (see dbSync) and returns the first name that actually resolves in the
    // current icon theme, falling back to a generic file icon.
    function resolveIcon(iconList) {
        var fallback = Quickshell.iconPath("application-x-generic", true)
        if (!iconList) return fallback

        var candidates = String(iconList).split(",")
        for (var i = 0; i < candidates.length; i++) {
            var name = candidates[i].trim()
            if (!name) continue
            var p = Quickshell.iconPath(name, true)
            if (p) return p
        }
        return fallback
    }

    // Double-click activation: launch .desktop entries, open folders in the
    // file manager, and hand every other file to the system default handler.
    function activateIcon(inode) {
        var idx = findIndexByInode(inode)
        if (idx === -1) return

        var entry = desktopIcons.get(idx)
        var fpath = desktopPath + "/" + entry.name

        if (entry.isDir) {
            Quickshell.execDetached({ command: ["nautilus", fpath] })
        } else if (String(entry.name).endsWith(".desktop")) {
            Quickshell.execDetached({ command: ["gio", "launch", fpath] })
        } else {
            Quickshell.execDetached({ command: ["xdg-open", fpath] })
        }
    }
}