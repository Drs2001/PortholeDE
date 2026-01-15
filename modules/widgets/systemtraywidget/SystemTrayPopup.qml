import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs.singletons

PopupWindow {
    id: trayPopup
    property var subMenuOpen: false
    property var minHeight: 41

    implicitWidth: 200
    implicitHeight: Math.max(trayIconsFlow.height, minHeight)
    color: "transparent"

     anchor {
        item: sysTrayButton
        rect.x: (sysTrayButton.width - width) / 2
        rect.y: -height - 20
    }

    Rectangle {
        id: trayBackground
        anchors.fill: parent
        color: Themes.primaryColor
        border.color: Themes.primaryHoverColor 
        border.width: 1.5
        radius: 10
    }

    Flow {
        id: trayIconsFlow
        width: parent.width
        spacing: 8
        padding: 8
        
        Repeater {
            id: items

            model: ScriptModel {
            values: [...SystemTray.items.values]
            }

            TrayItem {
            }
        }
    }

    onVisibleChanged: {
        if(visible){
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
        interval: 100
        onTriggered: {
            grab.active = true
        }
    }

    // Give focus to popup window to allow for keyboard inputs and clicking off detection
    HyprlandFocusGrab {
        id: grab
        windows: [ trayPopup ]

        onCleared: {
            if(!subMenuOpen){
                trayPopup.visible = false
            }
        }
    }
}