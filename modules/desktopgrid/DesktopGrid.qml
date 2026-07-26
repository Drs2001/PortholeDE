import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.singletons

Variants {
    required property int barHeight
    property var rightClickMenuOpen: false
    model: Quickshell.screens

    PanelWindow {
        id: gridWindow
        required property var modelData
        screen: modelData

        implicitWidth: screen.width
        implicitHeight: screen.height - barHeight
        visible: true
        aboveWindows: false
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            DropArea {
                anchors.fill: parent

                onEntered: function(drag) {
                    if(drag.hasUrls) {
                        drag.accept()
                    }
                }

                onDropped: function(drop) {
                    var desktopPath = Quickshell.env("HOME") + "/Desktop"
                    var draggedInode = drop.getDataAsString("application/x-desktop-icon")

                    if (draggedInode) {
                        var maxCols = Math.max(1, Math.floor(gridWindow.width / DesktopStateManager.cellWidth))
                        var maxRows = Math.max(1, Math.floor(gridWindow.height / DesktopStateManager.cellHeight))
                        DesktopStateManager.updateDesktopIconXY(draggedInode, drop.x, drop.y, screen.name, maxCols, maxRows)
                    }

                    if(drop.hasUrls){
                        var filePath = drop.urls[0].toString().replace("file://", "")
                        Quickshell.execDetached({
                            command: ["mv", filePath, desktopPath]
                        });
                    }
                }
            }

            MouseArea {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                anchors.fill: parent

                onClicked: event => {
                    if (event.button === Qt.LeftButton) {

                    } else if (event.button === Qt.RightButton) {
                        //TODO: Add right click menu that communicates with all windows
                    }
                }
            }

            Repeater {
                model: DesktopStateManager.desktopIcons
                delegate: DesktopIcon {
                    screenName: gridWindow.screen.name
                }
            }
        }
    }
}
