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

                    DesktopStateManager.updateDesktopIconXY(drop.getDataAsString("application/x-desktop-icon"), drop.x, drop.y, screen.name)

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
                delegate: Rectangle {
                    id: rect
                    property var hovered: false
                    width: 60
                    height: 60
                    color: hovered ? Qt.rgba(0.47, 0.44, 1, 0.33) : "transparent"
                    radius: 3
                    x: gridX
                    y: gridY
                    visible: {
                        if(model.screen === gridWindow.screen.name) {
                            return true
                        }
                        return false
                    }

                    Image {
                        id: iconImage
                        anchors.fill: parent
                        anchors.centerIn: parent
                        anchors.margins: 4
                        source: Quickshell.iconPath("folder", true)
                        fillMode: Image.PreserveAspectFit
                    }

                    HoverHandler {
                        id: baseHover

                        onHoveredChanged: {
                            rect.hovered = !rect.hovered
                        }
                    }
                    Drag.mimeData: {
                        "application/x-desktop-icon": String(index)
                    }
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.CopyAction
                    Drag.imageSource: Quickshell.iconPath("folder", true)
                    Drag.imageSourceSize: Qt.size(60, 60)

                    DragHandler {
                        id: dragger
                        target: null

                        onActiveChanged: {
                            if (active) {
                                parent.Drag.active = true
                                rect.hovered = true
                            } else {
                                parent.Drag.active = false
                                rect.hovered = false
                            }
                        }
                    }
                }
            }
        }
    }
}
