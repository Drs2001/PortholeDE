pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // Absolute path to the current wallpaper. Point a future wallpaper picker at
    // this property to swap the desktop background at runtime.
    property string path: Quickshell.env("HOME") + "/.config/porthole/wallpapers/spring.jpg"

    // URL form for Image.source.
    readonly property url source: "file://" + path
}
