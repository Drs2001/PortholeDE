import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import qs.singletons

Item {
    id: root

    required property SystemTrayItem modelData

    implicitWidth: 25
    implicitHeight: 25

    PopupWindow {
        id: trayItemPopup
        implicitWidth: 316
        implicitHeight: idMenu.contentHeight
        color: "transparent"

        anchor {
            item: root
            rect.x: (root.width - width) / 2
            rect.y: -height - 10
        }

        Rectangle {
            anchors.fill: parent
            color: Themes.primaryColor
            radius: 8
        }

        TrayItemMenu {
            id: idMenu
            rootMenu: QsMenuOpener { menu: modelData.menu }
            trayMenu: QsMenuOpener { menu: modelData.menu }
        }

        onVisibleChanged: {
            idMenu.trayMenu = idMenu.rootMenu
            if(visible){
                subMenuOpen = true
                grabTimer2.start()
            }
            else{
                subMenuOpen = false
                grab.active = true
            }
        }

        // Add a small delay to allow wayland to finish mapping the popupwindow
        // (Don't love this solution and will try to find a better one later)
        Timer {
            id: grabTimer2
            interval: 100
            onTriggered: {
                grab2.active = true
            }
        }

        // Give focus to popup window to allow for keyboard inputs and clicking off detection
        HyprlandFocusGrab {
            id: grab2
            windows: [ trayItemPopup ]

            onCleared: {
                trayItemPopup.visible = false
                trayPopup.visible = false
                grab.active = false
            }
        }
    }


    Rectangle {
        anchors.fill: parent
        color: mouse.hovered ? Themes.primaryHoverColor  : "transparent"
        radius: 5

        HoverHandler {
            id:mouse
        }

        IconImage {
            id: icon
            anchors.fill: parent
            anchors.margins: 4
            asynchronous: true
            source: {
                let icon = root.modelData.icon;
                if (icon.includes("?path=")) {
                    const [name, path] = icon.split("?path=");
                    icon = `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
                }
                return icon;
            }
        }

        MouseArea {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            anchors.fill: parent

            onClicked: event => {
                if (event.button === Qt.LeftButton) {
                    modelData.activate();
                } else if (event.button === Qt.RightButton) {
                    idMenu.trayMenu.menu = root.modelData.menu
                    trayItemPopup.visible = true
                }
            }
        }
        
    }

    Component.onDestruction: {
        grab.active = false
        grab2.active = false
        trayPopup.visible = false
    }
}