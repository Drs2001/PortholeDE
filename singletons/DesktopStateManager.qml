pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var test: "TEST"
    property var desktopIcons: [
        {
            inode: "3464076",
            path: "/home/dylan/Desktop/test",
            gridX: "0",
            gridY: "0",
            screen: "HDMI-A-1"
        },
        {
            inode: "34640767",
            path: "/home/dylan/Desktop/test",
            gridX: "0",
            gridY: "0",
            screen: "HDMI-A-1"
        }
    ]

    Connections {
        target: DesktopWatcher

        function onFileAdded(path, inode){
            console.log("FILE Added: ", inode)
        }
        function onFileRemoved(path, inode){
            console.log("FILE Removed: ", inode)
        }
        function onFileRenamed(path, inode){
            console.log(path)
            console.log("FILE Renamed: ", inode)
        }
    }

    Component.onCompleted: {

    }

    function updateDesktopIconXY(inode, x, y) {
        var item = desktopIcons.find(icon => icon.inode === inode)
        item.gridX = x
        item.gridY = y

        desktopIcons = [...desktopIcons]
    }
}