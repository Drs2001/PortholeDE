pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var test: "TEST"
    property var desktopIcons: ListModel {
        ListElement {
            inode: "3464076";
            path: "/home/dylan/Desktop/test";
            gridX: 0;
            gridY: 0;
            screen: "DP-3";
        }
    }

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

    function updateDesktopIconXY(index, x, y, screen) {
        desktopIcons.setProperty(index, "gridX", x)
        desktopIcons.setProperty(index, "gridY", y)
        desktopIcons.setProperty(index, "screen", screen)
    }
}