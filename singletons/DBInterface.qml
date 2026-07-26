pragma Singleton
import Quickshell
import QtQuick
import QtQuick.LocalStorage

Singleton {
    property var db: null

    Component.onCompleted: init()

    function init() {
        db = LocalStorage.openDatabaseSync(
            "DesktopDB",
            "1.0",
            "All persistent information relating to the desktop experience.",
            1000000
        )

        db.transaction(function(tx) {
            tx.executeSql(`
                CREATE TABLE IF NOT EXISTS desktopIcons(
                    inode TEXT PRIMARY KEY,
                    name TEXT,
                    isDir BOOL,
                    gridX INTEGER,
                    gridY INTEGER,
                    screen TEXT,
                    iconName TEXT
                )
            `)
        })
    }

    // Used to either update or create a new desktop icon entry
    function desktopIconEntryUpdate(inode, name, isDir, x, y, screen, iconName) { 
        db.transaction(function(tx) {
            tx.executeSql(`
            INSERT INTO desktopIcons (inode, name, isDir, gridX, gridY, screen, iconName)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(inode) DO UPDATE SET
                name   = excluded.name,
                isDir  = excluded.isDir,
                gridX  = excluded.gridX,
                gridY  = excluded.gridY,
                screen = excluded.screen,
                iconName = excluded.iconName
            `, [inode, name, isDir, x, y, screen, iconName])
        })
    }

    function desktopIconEntryUpdatePos(inode, name, isDir, x, y, screen, iconName) { 
        db.transaction(function(tx) {
            tx.executeSql(`
            INSERT INTO desktopIcons (inode, name, isDir, gridX, gridY, screen, iconName)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(inode) DO UPDATE SET
                gridX  = excluded.gridX,
                gridY  = excluded.gridY,
                screen = excluded.screen
            `, [inode, name, isDir, x, y, screen, iconName])
        })
    }

    // Update function used for initial boot / desktop refresh. Only touches the
    // name and iconName so a re-sync keeps the user's grid placement but still
    // picks up renames and updated file-type / .desktop icons.
    function desktopIconEntryDBSync(inode, name, isDir, x, y, screen, iconName) {
        db.transaction(function(tx) {
            tx.executeSql(`
            INSERT INTO desktopIcons (inode, name, isDir, gridX, gridY, screen, iconName)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(inode) DO UPDATE SET
                name     = excluded.name,
                iconName = excluded.iconName
            `, [inode, name, isDir, x, y, screen, iconName])
        })
    }

    function desktopIconEntryRemove(inode) {
        db.transaction(function(tx) {
            tx.executeSql(`
            DELETE FROM desktopIcons
            WHERE inode = ?
            `, [inode])
        })
    }

    function desktopIconEntryLookup(inode) {
        var iconEntry = null

        db.transaction(function(tx) {
            var query = tx.executeSql(`
            SELECT * FROM desktopIcons
            WHERE inode = ?
            `, [inode])

            if(query.rows.length > 0) {
                iconEntry = query.rows.item(0)
            }
        })

        return iconEntry
    }

    function desktopIconEntryGetAll() {
        var entries = null

        db.transaction(function(tx) {
            var query = tx.executeSql(`
            SELECT * FROM desktopIcons
            `)

            if(query.rows.length > 0) {
                entries = query.rows
            }
        })

        return entries
    }
}
