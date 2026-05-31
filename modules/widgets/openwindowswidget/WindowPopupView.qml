import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.singletons

PopupWindow {
    id: mainPopup
    property var buttonHovered: false
    property var addresses: []
    anchor.rect.y: -height - 20
    implicitHeight: backgroundRec.height
    implicitWidth: backgroundRec.width
    color: "transparent"

    function show(anchorItem, windowAddresses) {
        anchor.item = anchorItem
        buttonHovered = true
        addresses = windowAddresses

        updateVisibility()
    }

    function hide() {
        buttonHovered = false
        updateVisibility()
    }

    function updateVisibility() {
        if(buttonHovered || baseHover.hovered)
        {
            hideTimer.stop()
            visible = true
        }
        else {
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 100
        onTriggered: {
            visible = false
        }
    }
    
    // Popup window background
    Rectangle{
        id: backgroundRec
        implicitHeight: previewRowLayout.height
        implicitWidth: previewRowLayout.width
        color: Themes.primaryColor
        radius: 12

        // Row layout to hold all the windows associated with the application
        RowLayout{
            id: previewRowLayout
            spacing: 10

            // Display all open windows in the popup
             Repeater {
                model: addresses
                delegate: Rectangle{
                    id: delegateRoot
                    required property var modelData
                    property var window: Hyprland.toplevels.values.find(w => w.address == modelData)
                    property var padding: 15
                    property var isHovered: false
                    implicitWidth: columnLayout.implicitWidth + padding
                    implicitHeight: columnLayout.implicitHeight + padding
                    radius: 12
                    color: (isHovered || closeWindowButton.hovered) ? Themes.primaryHoverColor : Themes.primaryColor

                    ColumnLayout{
                        id: columnLayout
                        anchors.centerIn: parent
                        implicitWidth: screenCopyLoader.item ? screenCopyLoader.item.width : 10

                        RowLayout{
                            Text{
                                text: window ? window.title : ""
                                color: Themes.textColor
                                font.pixelSize: 12
                                elide: Text.ElideRight 
                                clip: true
                                Layout.fillWidth: true
                                Layout.maximumWidth: screenCopyLoader.item ? screenCopyLoader.item.width - closeWindowButton.width : 10
                            }
                            Button{
                                id: closeWindowButton
                                implicitHeight: 20
                                implicitWidth: 20
                                background: Rectangle {
                                    color: closeWindowButton.hovered ? "red" : "transparent"
                                    radius: 5
                                }
                                contentItem: Text{
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "\udb80\udd5a"
                                    color: Themes.textColor
                                }
                                Layout.alignment: Qt.AlignRight
                                onClicked:{
                                    if(window){
                                        if(addresses.length <= 1){
                                            mainPopup.visible = false
                                            window.wayland.close()
                                        }
                                        else{
                                            window.wayland.close()
                                            addresses = addresses.filter(add => add !== window.address)
                                        }
                                    }
                                }
                            }
                        }
                        Loader {
                            id: screenCopyLoader
                            active: (window !== undefined) && window.wayland
                            sourceComponent: WindowPreview {
                                waylandWindow: window.wayland
                            }
                        }
                    }
                    MouseArea {
                        id: singleWindowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        z: -1
                        
                        onClicked: {
                            if(window.workspace.id == -98){
                                 var workspaceId = Hyprland.focusedWorkspace.id

                                // We fullscreen temporarily here to fix a weird bug with hyprland where swapping workspaces while another window is fullscreend cause the sub window to turn invisible
                                // Recreate -> open two windows in the same workspace, fullscreen one to hide the other then change the workspace of the hidden window and it will turn invisible. 
                                // Toggling fullscreen forces a redraw because hyprland doesnt have a redraw command exposed.
                                // (May be fixed in future hyprland releases will check back on this)
                                // window.wayland.fullscreen = true
                                // window.wayland.fullscreen = false
                                //*****************************************************************************/

                                var dispatchStr = "hl.dsp.window.move({ workspace = " + workspaceId + ", follow = false, window = 'address:0x" + window.address + "' })"
                                Hyprland.dispatch(dispatchStr)
                                window.wayland.activate()
                            }
                            else{
                                // Wont move mouse cursor and focus if window is already focused by hyprland
                                window.wayland.activate()
                            }
                        }

                        onContainsMouseChanged: {
                            if(singleWindowArea.containsMouse){
                                isHovered = true
                            }
                            else{
                                isHovered = false
                            }
                        }
                    }
                }
            }

            HoverHandler {
                id: baseHover

                onHoveredChanged: {
                    updateVisibility()
                }
            }
        }
    }
}