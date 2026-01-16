import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.singletons
import qs.modules.widgets.startwidget

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

                ColumnLayout {
                    width: parent.width

                    Repeater {
                        model: ApplicationsManager.entries
                        delegate: ColumnLayout {
                            required property var modelData
                            required property int index
                            spacing: 5
                            Layout.fillWidth: true
                            Text {
                                visible: index === 0 || 
                                        modelData.name.charAt(0).toUpperCase() !== 
                                        ApplicationsManager.entries[index - 1].name.charAt(0).toUpperCase()
                                text: modelData.name.charAt(0).toUpperCase()
                                color: Themes.textColor
                                font.pixelSize: 16
                                Layout.fillWidth: true
                            }
                            ApplicationButton{
                                application: modelData
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
        
    }
}