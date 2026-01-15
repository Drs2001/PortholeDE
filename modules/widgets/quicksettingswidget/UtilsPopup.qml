import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.singletons

LazyLoader{
    loading: true

    PopupWindow {
        id: popup
        anchor.item: root
        anchor.rect.y: -height - 20
        implicitWidth: 340
        implicitHeight: rootStack.currentItem.implicitHeight
        color: "transparent"

        Rectangle {
            id: trayBackground
            anchors.fill: parent
            color: Themes.popupBackgroundColor
            radius: 10

            StackView {
                id: rootStack
                initialItem: "MainMenu.qml" // We initialize with the file directly as QML automatically wraps seperate files as components
                anchors.fill: parent
            }
        }

        // Check if the stack has more than the main menu view on it and if so reset it to display the main menu
        onVisibleChanged: {
            if(visible){
                if(rootStack.depth > 1){
                    rootStack.pop(null, StackView.Immediate)
                }
                grabTimer.start()
            }
            else{
                menuOpen = false
            }
        }

        // Add a small delay to allow wayland to finish mapping the popupwindow
        // (Don't love this solution and will try to find a better one later)
        Timer {
            id: grabTimer
            interval: 50
            onTriggered: {
                grab.active = true
            }
        }

        // Give focus to popup window to allow for keyboard inputs and clicking off detection
        HyprlandFocusGrab {
            id: grab
            windows: [ popup ]

            onCleared: {
                popup.visible = false
            }
        }
    }
}