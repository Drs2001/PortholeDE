import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.singletons

PanelWindow {
    id: appLauncher
    visible: false
    focusable: true
    implicitWidth: 600
    implicitHeight: 400
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top

    onVisibleChanged: {
        if(visible){
            grab.active = true
            searchBar.focus = true
        }
        else{
            searchBar.focus = false
            searchBar.text = ""
            scroll.ScrollBar.vertical.position = 0
            ApplicationsManager.updateEntries()
            grab.active = false

        }
    }
    
    HyprlandFocusGrab {
        id: grab
        windows: [ appLauncher ]

        onCleared: {
            appLauncher.visible = false
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Themes.primaryColor 

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Down) {
                listView.incrementCurrentIndex()
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                listView.decrementCurrentIndex()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                listView.currentItem?.run()
                event.accepted = true
            }
        }

        ColumnLayout {
            anchors.fill: parent

            TextField {
                id: searchBar
                Layout.fillWidth: true
                Layout.margins: 15
                placeholderText: qsTr("Search for apps")
                color: Themes.textColor
                placeholderTextColor: Themes.textColor

                background: Rectangle {
                    implicitHeight: 10
                    implicitWidth: parent.width
                    color: "transparent"
                    radius: 5
                }

                onTextEdited: {
                    ApplicationsManager.updateEntries(searchBar.text)
                }
            }

            ScrollView {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 15
                Layout.rightMargin: 15

                contentWidth: availableWidth

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    keyNavigationEnabled: false
                    currentIndex: 0
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 0
                    highlight: Rectangle {
                        color: Themes.primaryHoverColor
                        radius: 6
                    }
                    model: ApplicationsManager.entries

                    delegate: Button {
                        required property var modelData
                        required property int index
                        width: listView.width

                        contentItem: Row{
                            spacing: 8

                            Image {
                                source: Quickshell.iconPath(modelData.icon, true)
                                height: 24
                                width: 24
                                fillMode: Image.PreserveAspectFit
                            }
                            Text{
                                text: modelData.name
                                color: Themes.textColor
                            }
                        }

                        background: Rectangle {
                            color: "transparent"
                            radius: 6
                        }

                        onClicked: {
                            if(listView.currentIndex === index) {
                                run()
                            }
                            else {
                                listView.currentIndex = index
                            }
                        }

                        function run() {
                            if (modelData.runInTerminal) {
                                Quickshell.execDetached({
                                    command: ["kitty", ...modelData.command],
                                    workingDirectory: modelData.workingDirectory
                                })
                            } 
                            else {
                                modelData.execute()
                            }
                            appLauncher.visible = false
                        }
                    }
                    
                }
            }
        }
        
    }
}