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

                    // Set when we've asked hyprland to pull this window out of the minimized special
                    // workspace. We only activate once hyprland reports the move as done, otherwise
                    // activating a window that's still on a hidden special workspace makes hyprland
                    // open that special workspace on the current monitor (and bind it there).
                    property bool pendingActivate: false
                    property var currentWorkspace: window ? window.workspace : null

                    function isOnMinimizedWorkspace() {
                        return currentWorkspace !== null && currentWorkspace !== undefined
                            && currentWorkspace.name === "special:minimized"
                    }

                    function tryPendingActivate() {
                        if (pendingActivate && window && window.wayland && !isOnMinimizedWorkspace()) {
                            pendingActivate = false
                            activateFallback.stop()
                            window.wayland.activate()
                        }
                    }

                    onCurrentWorkspaceChanged: tryPendingActivate()

                    Connections {
                        target: delegateRoot.currentWorkspace
                        ignoreUnknownSignals: true
                        function onNameChanged() { delegateRoot.tryPendingActivate() }
                    }

                    // Safety net in case the workspace update event is missed; never activates
                    // while the window is still on the special workspace.
                    Timer {
                        id: activateFallback
                        interval: 300
                        onTriggered: {
                            delegateRoot.tryPendingActivate()
                            delegateRoot.pendingActivate = false
                        }
                    }

                    // Quickshell permanently ends a live screencopy if hyprland fails a frame (e.g. while
                    // the window moves to/from a hidden special workspace). Recreate the preview whenever
                    // the window changes workspace so the capture restarts instead of staying blank.
                    property bool captureEnabled: true
                    property string workspaceName: currentWorkspace ? currentWorkspace.name : ""
                    onWorkspaceNameChanged: {
                        captureEnabled = false
                        Qt.callLater(() => delegateRoot.captureEnabled = true)
                    }

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
                                font.family: Themes.textFont
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
                            // Only capture while the popup is showing; this also gives every open a fresh capture
                            active: mainPopup.visible && delegateRoot.captureEnabled && (window !== undefined) && !!window.wayland
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
                            if(!window) return
                            if(delegateRoot.isOnMinimizedWorkspace()){
                                 var workspaceId = Hyprland.focusedWorkspace.id

                                // We fullscreen temporarily here to fix a weird bug with hyprland where swapping workspaces while another window is fullscreend cause the sub window to turn invisible
                                // Recreate -> open two windows in the same workspace, fullscreen one to hide the other then change the workspace of the hidden window and it will turn invisible. 
                                // Toggling fullscreen forces a redraw because hyprland doesnt have a redraw command exposed.
                                // (May be fixed in future hyprland releases will check back on this)
                                // window.wayland.fullscreen = true
                                // window.wayland.fullscreen = false
                                //*****************************************************************************/

                                var dispatchStr = "hl.dsp.window.move({ workspace = " + workspaceId + ", follow = false, window = 'address:0x" + window.address + "' })"
                                // Dispatch is async: don't activate here, wait for hyprland to report the move
                                delegateRoot.pendingActivate = true
                                activateFallback.restart()
                                // Close right away; otherwise the preview gets rebuilt on the workspace change
                                // and the popup sits there blank until the hover timers close it
                                hideTimer.stop()
                                mainPopup.visible = false
                                Hyprland.dispatch(dispatchStr)
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