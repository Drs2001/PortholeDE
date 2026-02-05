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
                    path TEXT,
                    gridX INTEGER,
                    gridY INTEGER,
                    screen TEXT
                )
            `)
        })
    }

    // Used to either update or create a new desktop icon entry
    function desktopIconEntryUpdate(inode, path, x, y, screen) { 
        db.transaction(function(tx) {
            tx.executeSql(`
            INSERT INTO desktopIcons (inode, path, gridX, gridY, screen)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(inode) DO UPDATE SET
                path   = excluded.path,
                gridX  = excluded.gridX,
                gridY  = excluded.gridY,
                screen = excluded.screen
            `, [inode, path, x, y, screen])
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
}
