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

            Rectangle {
                id: rect
                width: 50
                height: 50
                color: "red"

                Drag.mimeData: {
                    "text/plain": "TEST"
                }
                Drag.dragType: Drag.Automatic
                Drag.supportedActions: Qt.CopyAction

                DragHandler {
                    id: dragger
                    target: null

                    onActiveChanged: {
                        if (active) {
                             parent.grabToImage(function(result) {
                                parent.Drag.imageSource = result.url
                                parent.Drag.active = true
                            })
                        } else {
                            parent.Drag.active = false
                        }
                    }
                }
            }
        }
    }
}
