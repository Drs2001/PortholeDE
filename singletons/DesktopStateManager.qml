pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var desktopPath: Quickshell.env("HOME") + "/Desktop"
    property var desktopIcons: ListModel {}

    // Inodes (as strings) of the currently-selected icons. Reassigned as a whole
    // on every change so delegate bindings re-evaluate.
    property var selectedInodes: []

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
                if (isSelected(realInode)) toggleSelection(realInode)
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

    // ── Selection ────────────────────────────────────────────────────────────
    function isSelected(inode) {
        return selectedInodes.indexOf(String(inode)) !== -1
    }

    // Plain left-click: this icon becomes the sole selection.
    function selectOnly(inode) {
        selectedInodes = [String(inode)]
    }

    // Ctrl+click: add/remove this icon from the multi-selection.
    function toggleSelection(inode) {
        var s = String(inode)
        var arr = selectedInodes.slice()
        var i = arr.indexOf(s)
        if (i === -1) arr.push(s)
        else arr.splice(i, 1)
        selectedInodes = arr
    }

    // Click on empty desktop: drop the whole selection.
    function clearSelection() {
        if (selectedInodes.length > 0) selectedInodes = []
    }

    // ── Rubber-band (marquee) selection ──────────────────────────────────────
    // The rectangle is tracked in a shared "virtual global" coordinate space
    // (each monitor's screen.x/screen.y + window-local pixels) so the box can be
    // dragged across monitors: the origin window keeps the pointer grab, and
    // every grid window renders the slice of the rectangle that overlaps it.
    property bool marqueeActive: false
    property real marqueeX1: 0
    property real marqueeY1: 0
    property real marqueeX2: 0
    property real marqueeY2: 0
    property var marqueeBase: []

    function beginMarquee(gx, gy, baseInodes) {
        marqueeBase = baseInodes ? baseInodes : []
        marqueeX1 = gx; marqueeY1 = gy
        marqueeX2 = gx; marqueeY2 = gy
        marqueeActive = true
    }

    function updateMarquee(gx, gy) {
        if (!marqueeActive) return
        marqueeX2 = gx; marqueeY2 = gy
        selectInRectGlobal(marqueeX1, marqueeY1, marqueeX2, marqueeY2, marqueeBase)
    }

    function endMarquee() {
        marqueeActive = false
    }

    // Selects every icon (on ANY monitor) whose box intersects the global
    // rectangle, unioned with `baseInodes` (preserved when Ctrl is held).
    function selectInRectGlobal(x1, y1, x2, y2, baseInodes) {
        var minX = Math.min(x1, x2), maxX = Math.max(x1, x2)
        var minY = Math.min(y1, y2), maxY = Math.max(y1, y2)
        var iconW = 70, iconH = 80

        var result = baseInodes ? baseInodes.slice() : []
        for (var i = 0; i < desktopIcons.count; i++) {
            var e = desktopIcons.get(i)
            var so = screenObjByName(e.screen)
            if (!so) continue
            var ix = so.x + e.gridX * cellWidth
            var iy = so.y + e.gridY * cellHeight
            if (ix < maxX && ix + iconW > minX && iy < maxY && iy + iconH > minY) {
                var s = String(e.inode)
                if (result.indexOf(s) === -1) result.push(s)
            }
        }
        selectedInodes = result
    }

    // ── Drag (multi-select move with live preview) ───────────────────────────
    // Uses native Qt DnD purely for cross-monitor event ROUTING: each grid
    // window's DropArea reports which monitor the cursor is over and the local
    // coordinates there (updateDragHover / dropDrag). The moving payload lives
    // in dragItems here, and DesktopGrid renders the ghost preview off this
    // state on whichever monitor currently has the cursor (dragScreen).
    property bool dragActive: false
    property string dragScreen: ""      // monitor the cursor is currently over
    property real dragPosX: 0           // cursor position, local to dragScreen
    property real dragPosY: 0
    // [{inode, gridX, gridY, relCol, relRow, iconPath, displayName}] — relCol/relRow
    // are each icon's offset from the grabbed ("primary") icon, so the group keeps
    // its arrangement when dropped (even onto another monitor).
    property var dragItems: []
    // Inode of the folder currently hovered as a "drop into" target ("" = none).
    property string dragFolderTarget: ""

    function isDraggingInode(inode) {
        for (var i = 0; i < dragItems.length; i++) {
            if (dragItems[i].inode === String(inode)) return true
        }
        return false
    }

    function displayNameFor(name) {
        var n = String(name)
        return n.endsWith(".desktop") ? n.slice(0, -8) : n
    }

    function screenObjByName(name) {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
        }
        return null
    }

    // Drag start. If the grabbed icon is part of a multi-selection the whole
    // selection (on this monitor) moves together; otherwise it becomes the sole
    // selection. Only icons on the primary's monitor join the drag, so their
    // relative offsets are well-defined.
    function beginDrag(primaryInode, screenName) {
        var inodes
        if (isSelected(primaryInode) && selectedInodes.length > 1) {
            inodes = selectedInodes.slice()
        } else {
            selectOnly(primaryInode)
            inodes = [String(primaryInode)]
        }

        var pIdx = findIndexByInode(primaryInode)
        if (pIdx === -1) return
        var p = desktopIcons.get(pIdx)

        var items = []
        for (var i = 0; i < inodes.length; i++) {
            var idx = findIndexByInode(inodes[i])
            if (idx === -1) continue
            var e = desktopIcons.get(idx)
            if (e.screen !== screenName) continue
            items.push({
                inode: String(e.inode),
                gridX: e.gridX,
                gridY: e.gridY,
                relCol: e.gridX - p.gridX,
                relRow: e.gridY - p.gridY,
                iconPath: e.isDir ? Quickshell.iconPath("folder", true) : resolveIcon(e.iconName),
                displayName: displayNameFor(e.name)
            })
        }

        dragItems = items
        dragScreen = screenName
        dragPosX = (p.gridX + 0.5) * cellWidth
        dragPosY = (p.gridY + 0.5) * cellHeight
        dragActive = true
    }

    // Called continuously by the DropArea under the cursor.
    function updateDragHover(screenName, x, y) {
        if (!dragActive) return
        dragScreen = screenName
        dragPosX = x
        dragPosY = y
        // Highlight a folder if the cursor is over one (and it's not itself
        // being dragged) — that's the "drop into folder" target.
        dragFolderTarget = folderInodeAt(screenName, x, y, dragItems)
    }

    function clearDragState() {
        dragActive = false
        dragItems = []
        dragFolderTarget = ""
    }

    // Returns the inode of a folder occupying the cell under (x,y) on screenName,
    // excluding any folder that's part of the drag, or "" if there's none.
    function folderInodeAt(screenName, x, y, movingItems) {
        var col = Math.floor(x / cellWidth)
        var row = Math.floor(y / cellHeight)

        var moving = {}
        if (movingItems) for (var m = 0; m < movingItems.length; m++) moving[String(movingItems[m].inode)] = true

        for (var i = 0; i < desktopIcons.count; i++) {
            var e = desktopIcons.get(i)
            if (e.screen !== screenName || !e.isDir) continue
            if (moving[String(e.inode)]) continue
            if (e.gridX === col && e.gridY === row) return String(e.inode)
        }
        return ""
    }

    // Drop handler. If the cursor is over a folder, move the dragged files INTO
    // that folder; otherwise reposition them on the grid. `items` is decoded from
    // the drop's mime data (not the shared preview state).
    function dropItemsAt(items, screenName, x, y) {
        if (items && items.length > 0) {
            var folder = folderInodeAt(screenName, x, y, items)
            if (folder) {
                moveIntoFolder(items, folder)
            } else {
                var so = screenObjByName(screenName)
                var maxCols = so ? Math.max(1, Math.floor(so.width / cellWidth)) : 10
                var maxRows = so ? Math.max(1, Math.floor(so.height / cellHeight)) : 10
                var baseCol = Math.max(0, Math.min(Math.floor(x / cellWidth), maxCols - 1))
                var baseRow = Math.max(0, Math.min(Math.floor(y / cellHeight), maxRows - 1))
                moveItemsTo(items, baseCol, baseRow, screenName, maxCols, maxRows)
            }
        }
        clearDragState()
    }

    // Moves each dragged file into the target folder on disk. The DesktopWatcher
    // sees the files leave ~/Desktop and removes them from the model/DB.
    function moveIntoFolder(items, folderInode) {
        var fIdx = findIndexByInode(folderInode)
        if (fIdx === -1) return
        var folderPath = desktopPath + "/" + desktopIcons.get(fIdx).name

        for (var i = 0; i < items.length; i++) {
            if (String(items[i].inode) === String(folderInode)) continue
            var idx = findIndexByInode(items[i].inode)
            if (idx === -1) continue
            var src = desktopPath + "/" + desktopIcons.get(idx).name
            Quickshell.execDetached({ command: ["mv", src, folderPath + "/"] })
        }
    }

    // Places each item at (baseCol+relCol, baseRow+relRow) on the target screen,
    // resolving collisions against static (non-moving) icons and each other.
    // Also reassigns each icon's monitor (screen) so cross-monitor drops persist.
    function moveItemsTo(items, baseCol, baseRow, screen, maxCols, maxRows) {
        var moving = {}
        for (var i = 0; i < items.length; i++) moving[items[i].inode] = true

        var taken = {}
        function cellKey(c, r) { return c + "," + r }

        function occupiedByStatic(col, row) {
            for (var k = 0; k < desktopIcons.count; k++) {
                var e = desktopIcons.get(k)
                if (e.screen !== screen) continue
                if (moving[String(e.inode)]) continue
                if (e.gridX === col && e.gridY === row) return true
            }
            return false
        }

        function freeCell(col, row) {
            col = Math.max(0, Math.min(col, maxCols - 1))
            row = Math.max(0, Math.min(row, maxRows - 1))
            if (!occupiedByStatic(col, row) && !taken[cellKey(col, row)]) return { col: col, row: row }
            var maxRadius = Math.max(maxCols, maxRows)
            for (var radius = 1; radius <= maxRadius; radius++) {
                for (var dy = -radius; dy <= radius; dy++) {
                    for (var dx = -radius; dx <= radius; dx++) {
                        if (Math.max(Math.abs(dx), Math.abs(dy)) !== radius) continue
                        var c = col + dx, r = row + dy
                        if (c < 0 || c >= maxCols || r < 0 || r >= maxRows) continue
                        if (!occupiedByStatic(c, r) && !taken[cellKey(c, r)]) return { col: c, row: r }
                    }
                }
            }
            return { col: col, row: row }
        }

        for (var j = 0; j < items.length; j++) {
            var it = items[j]
            var cell = freeCell(baseCol + it.relCol, baseRow + it.relRow)
            taken[cellKey(cell.col, cell.row)] = true
            var idx = findIndexByInode(it.inode)
            if (idx === -1) continue
            desktopIcons.setProperty(idx, "gridX", cell.col)
            desktopIcons.setProperty(idx, "gridY", cell.row)
            desktopIcons.setProperty(idx, "screen", screen)
            var e2 = desktopIcons.get(idx)
            DBInterface.desktopIconEntryUpdatePos(e2.inode, e2.name, e2.isDir, e2.gridX, e2.gridY, e2.screen, e2.iconName)
        }
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