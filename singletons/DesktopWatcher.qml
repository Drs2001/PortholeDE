pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    property string watchPath: Quickshell.env("HOME") + "/Desktop"
    property var renameBuffer: ({})
    
    property var process: Process {
        running: true
        // Needed the output of inotifywait to be piped into the stat command to get the files inode value
        command: ["sh", "-c", 
                    `inotifywait -m -e create,delete,close_write,moved_to,moved_from --format "%w|%e|%f|%c" "${watchPath}" | 
                    while IFS="|" read -r path event file cookie; do
                        # Try to get the inode. If file is deleted, stat fails, so we return 0.
                        inode=$(stat -c %i "$path$file" 2>/dev/null || echo "0")
                        echo "$path|$event|$file|$cookie|$inode"
                    done`
        ]
        
        stdout: SplitParser {
            onRead: function(data) {
                var parts = data.trim().split("|")
                var path = parts[0]
                var event = parts[1]
                var filename = parts[2]
                var renameCookie = parts[3] //inotify emits a cookie to match the moved_from and moved_to events for a rename
                var inode = parts[4]

                var fullPath = path + filename

                if (event.includes("CREATE")) {
                    root.fileAdded(inode, filename)
                } else if (event.includes("DELETE")) {
                    root.fileRemoved(inode, filename)
                } else if (event.includes("MOVED_FROM")) {
                    renameBuffer[renameCookie] = {
                        from: fullPath,
                        to: null,
                        inode: inode,
                        filename: filename
                    }
                    renameTimer.restart()
                } else if (event.includes("MOVED_TO")) {
                    if(!renameBuffer[renameCookie]){
                        renameBuffer[renameCookie] = {}
                    }
                    renameBuffer[renameCookie].to = fullPath
                    renameBuffer[renameCookie].inode = inode
                    renameBuffer[renameCookie].filename = filename
                    renameTimer.restart()
                }
            }
        }
    }

    // Buffer timer is used to identify renames of files and folders and send the appropriate signal
    Timer {
        id: renameTimer
        interval: 150
        repeat: false
        onTriggered: {
            for (var cookie in renameBuffer) {
                var r = renameBuffer[cookie]

                if (r.from && r.to) {
                    root.fileRenamed(r.inode, r.filename)
                } else if (r.from) {
                    root.fileRemoved(r.inode, r.filename)
                } else if (r.to) {
                    root.fileAdded(r.inode, r.filename)
                }
            }

            renameBuffer = ({})
        }
    }
    
    // We use only 3 signals for simplicity as a move_from event and deleted event are essentially the same thing for this purpose
    signal fileAdded(string inode, string filename)
    signal fileRemoved(string inode, string filename)
    signal fileRenamed(string inode, string filename)
}