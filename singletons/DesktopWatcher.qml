pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    property string watchPath: Quickshell.env("HOME") + "/Desktop"
    property var debounceTimers: ({})
    
    property var process: Process {
        running: true
        command: ["inotifywait", "-m", "-e", "create,delete,modify,moved_to,moved_from", 
                  watchPath]
        
        stdout: SplitParser {
            onRead: function(data) {
                var parts = data.trim().split(/[\s,]+/)
                var path = parts[0]
                var event = parts[1]
                var isDir = false
                var filename = ""
                
                if(data.includes("ISDIR")) {
                    isDir = true
                    filename = parts[3]
                }
                else {
                    filename = parts[2] 
                }
                var fullPath = path + filename

                if (event === "MODIFY") {
                    root.fileModified(fullPath)
                } else if (event === "CREATE") {
                    root.fileCreated(fullPath)
                } else if (event === "DELETE") {
                    root.fileDeleted(fullPath)
                } else if (event.includes("MOVED_FROM")) {
                    root.fileMovedFrom(fullPath)
                } else if (event.includes("MOVED_TO")) {
                    root.fileMovedTo(fullPath)
                }
            }
        }
    }
    
    signal fileCreated(string path)
    signal fileDeleted(string path)
    signal fileModified(string path)
    signal fileMovedFrom(string path)
    signal fileMovedTo(string path)
}