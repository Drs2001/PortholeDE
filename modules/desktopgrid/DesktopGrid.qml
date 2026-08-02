import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
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

        // Without on-demand keyboard focus, a layer-shell surface never receives
        // modifier state, so pointer events report modifiers == 0 and Ctrl+click
        // can't be distinguished from a plain click.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            // Receives both files dragged in from other apps AND desktop-icon
            // drags (the native DnD is what carries an icon drag across monitors
            // to the target screen's DropArea).
            DropArea {
                id: dropArea
                anchors.fill: parent

                readonly property string iconMime: "application/x-porthole-desktop-icon"

                onEntered: function(drag) {
                    if (drag.hasUrls || drag.formats.indexOf(iconMime) !== -1) {
                        drag.accept()
                    }
                    if (!drag.hasUrls) {
                        DesktopStateManager.updateDragHover(gridWindow.screen.name, drag.x, drag.y)
                    }
                }

                onPositionChanged: function(drag) {
                    if (!drag.hasUrls) {
                        DesktopStateManager.updateDragHover(gridWindow.screen.name, drag.x, drag.y)
                    }
                }

                onDropped: function(drop) {
                    if (drop.hasUrls) {
                        var desktopPath = Quickshell.env("HOME") + "/Desktop"
                        var filePath = drop.urls[0].toString().replace("file://", "")
                        Quickshell.execDetached({
                            command: ["mv", filePath, desktopPath]
                        });
                        return
                    }

                    var raw = drop.getDataAsString(iconMime)
                    if (raw) {
                        DesktopStateManager.dropItemsAt(JSON.parse(raw), gridWindow.screen.name, drop.x, drop.y)
                    }
                }
            }

            MouseArea {
                id: bgMouse
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                anchors.fill: parent

                // Local pixels -> shared "virtual global" space (see
                // DesktopStateManager), so the marquee can span monitors.
                readonly property real originX: gridWindow.screen.x
                readonly property real originY: gridWindow.screen.y

                onPressed: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        // Ctrl keeps the existing selection and adds to it.
                        var additive = (mouse.modifiers & Qt.ControlModifier)
                        var base = additive ? DesktopStateManager.selectedInodes.slice() : []
                        if (!additive) DesktopStateManager.clearSelection()
                        DesktopStateManager.beginMarquee(originX + mouse.x, originY + mouse.y, base)
                    }
                }

                onPositionChanged: mouse => {
                    if (DesktopStateManager.marqueeActive) {
                        DesktopStateManager.updateMarquee(originX + mouse.x, originY + mouse.y)
                    }
                }

                onReleased: mouse => {
                    DesktopStateManager.endMarquee()
                }

                onClicked: event => {
                    if (event.button === Qt.RightButton) {
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

            // Blue rubber-band selection rectangle (drawn above the icons). The
            // rectangle lives in shared global coords; each monitor converts it to
            // its own local space (subtracting screen.x/y) and the window clips it,
            // so a marquee spanning monitors shows its slice on each one.
            Rectangle {
                id: marqueeRect
                z: 50
                visible: DesktopStateManager.marqueeActive
                x: Math.min(DesktopStateManager.marqueeX1, DesktopStateManager.marqueeX2) - gridWindow.screen.x
                y: Math.min(DesktopStateManager.marqueeY1, DesktopStateManager.marqueeY2) - gridWindow.screen.y
                width: Math.abs(DesktopStateManager.marqueeX2 - DesktopStateManager.marqueeX1)
                height: Math.abs(DesktopStateManager.marqueeY2 - DesktopStateManager.marqueeY1)
                color: Qt.rgba(0.3, 0.5, 1, 0.22)
                border.width: 1
                border.color: Qt.rgba(0.3, 0.5, 1, 0.9)
            }

            // Live drag preview, drawn on whichever monitor currently has the
            // cursor (dragScreen): target-cell outlines at the snapped drop
            // location, plus ghost icons following the cursor — for one or all
            // selected icons. Because it only renders when dragScreen matches this
            // window, the preview naturally hops monitors as the cursor crosses.
            Item {
                id: dragPreview
                anchors.fill: parent
                z: 100
                visible: DesktopStateManager.dragActive
                         && DesktopStateManager.dragScreen === gridWindow.screen.name

                property real cw: DesktopStateManager.cellWidth
                property real ch: DesktopStateManager.cellHeight
                // Cell under the cursor = where the grabbed (primary) icon lands.
                property int baseCol: Math.floor(DesktopStateManager.dragPosX / cw)
                property int baseRow: Math.floor(DesktopStateManager.dragPosY / ch)

                // Snapped target-cell outlines (primary + relative offsets).
                Repeater {
                    model: DesktopStateManager.dragItems
                    delegate: Rectangle {
                        required property var modelData
                        width: 70
                        height: 80
                        x: Math.max(0, dragPreview.baseCol + modelData.relCol) * dragPreview.cw
                        y: Math.max(0, dragPreview.baseRow + modelData.relRow) * dragPreview.ch
                        color: Qt.rgba(0.47, 0.44, 1, 0.12)
                        radius: 3
                        border.width: 2
                        border.color: Qt.rgba(0.47, 0.44, 1, 0.85)
                    }
                }

                // Ghost icons following the cursor: primary centered on the
                // cursor, the rest offset by their relative grid position.
                Repeater {
                    model: DesktopStateManager.dragItems
                    delegate: Column {
                        required property var modelData
                        width: 70
                        // NOTE: opacity goes on the leaf items below, NOT here.
                        // Group opacity (<1 on an item with children) forces an
                        // offscreen render pass per frame per ghost, which is what
                        // made multi-icon drags lag.
                        x: DesktopStateManager.dragPosX - dragPreview.cw / 2 + modelData.relCol * dragPreview.cw
                        y: DesktopStateManager.dragPosY - dragPreview.ch / 2 + modelData.relRow * dragPreview.ch
                        spacing: 4

                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitSize: 50
                            opacity: 0.75
                            source: modelData.iconPath
                        }
                        Text {
                            font.family: Themes.textFont
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: 12
                            color: "white"
                            opacity: 0.75
                            text: modelData.displayName
                        }
                    }
                }
            }
        }
    }
}
