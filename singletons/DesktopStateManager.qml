pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var test: "TEST"
    property var desktopPath: Quickshell.env("HOME") + "/Desktop"
    property var desktopIcons: ListModel {}

    Connections {
        target: DesktopWatcher

        function onFileAdded(path, inode, filename){
            console.log("FILE Added: ", inode)
        }
        function onFileRemoved(path, inode, filename){
            console.log("FILE Removed: ", inode)
        }
        function onFileRenamed(path, inode, filename){
            console.log("FILE Renamed: ", inode)
        }
    }

    Process {
        id: dbSync
        running: true
        command: ["find", desktopPath, "-mindepth", "1", "-maxdepth", "1", "-printf", "%i|%y|%f\n"]

        stdout: StdioCollector {
            onStreamFinished: {
                var folderEntries = this.text.split("\n")
                for(const entry of folderEntries) {
                    if(entry){
                        var info = entry.split("|")
                        DBInterface.desktopIconEntryDBSync(info[0], info[2], (info[1] == "d"), 0, 0, "HDMI-A-1", "")
                    }
                }

                refreshDesktopFromDB()
            }
        }
    }

    function refreshDesktopFromDB() {
        var entries = DBInterface.desktopIconEntryGetAll()

        for(var i = 0; i < entries.length; i++) {
            var entry = entries.item(i)
            desktopIcons.append({
                inode: entry.inode,
                name: entry.name,
                isDir: entry.isDir,
                gridX: entry.gridX,
                gridY: entry.gridY,
                screen: entry.screen,
                iconName: entry.iconName
            })
        }
    }

    function updateDesktopIconXY(index, x, y, screen) {
        desktopIcons.setProperty(index, "gridX", x)
        desktopIcons.setProperty(index, "gridY", y)
        desktopIcons.setProperty(index, "screen", screen)

        var entry = desktopIcons.get(index)
        DBInterface.desktopIconEntryUpdatePos(entry.inode, entry.name, entry.isDir, entry.gridX, entry.gridY, entry.screen, entry.iconName)
    }
}