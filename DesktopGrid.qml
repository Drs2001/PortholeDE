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

            // Repeater {
            //     id: grid
                
            //     model: ListModel {
            //         ListElement {
            //             name: "Bob"
            //             xPos: 10
            //             yPos: 10
            //         }
            //         ListElement {
            //             name: "TEST"
            //             xPos: 68
            //             yPos: 10
            //         }
            //     }

            //     delegate: Item {
            //         id: testItem
            //         required property string name
            //         required property string xPos
            //         required property string yPos
            //         x: xPos
            //         y: yPos
            //         Button {
            //             id: testButton
            //             implicitHeight: 48
            //             implicitWidth: 48
            //             text: name
            //         }

            //         MouseArea {
            //             drag.target: testButton
            //         }
            //     }
            // }

            Rectangle {
                id: rect
                width: 50; height: 50
                color: "red"

                MouseArea {
                    anchors.fill: parent
                    drag.target: rect
                    // drag.axis: Drag.XAxis
                    // drag.minimumX: 0
                    // drag.maximumX: container.width - rect.width
                }
            }
        }
    }
}
