import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.singletons

// Desktop wallpaper, drawn by Quickshell itself (replaces hyprpaper). One
// full-screen surface per monitor on the bottom-most layer, so the desktop grid
// and windows sit above it — and the glass bar has content behind it to blur.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: wallpaperWindow
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "porthole-wallpaper"
        // Ignore exclusive zones so it fills the ENTIRE monitor, including under
        // the bar (otherwise the bar's reserved space would leave a gap here).
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "black"   // shown briefly while the image loads / behind letterboxing

        Image {
            anchors.fill: parent
            source: WallpaperManager.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            // Decode at monitor resolution so a large wallpaper is crisp + cheap.
            sourceSize: Qt.size(wallpaperWindow.screen.width, wallpaperWindow.screen.height)
        }
    }
}
