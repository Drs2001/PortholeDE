import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.singletons

// A single desktop icon (file or folder) rendered inside DesktopGrid's Repeater.
// Model roles (inode, name, isDir, gridX, gridY, screen, iconName) are injected
// by the Repeater; screenName is passed in so we can tell whether this icon
// belongs on the monitor this grid instance is drawn on.
Rectangle {
    id: rect

    // NOTE: keep this a plain (non-required) property. Declaring ANY required
    // property on a Repeater delegate flips Qt into "required properties mode"
    // and stops injecting model roles as context properties, which breaks every
    // model.xxx binding below.
    property string screenName

    // Selection is tracked centrally (so Ctrl+click can build a multi-selection
    // across the whole grid); this reruns whenever that set is reassigned.
    property bool selected: DesktopStateManager.selectedInodes.indexOf(String(model.inode)) !== -1
    // True when a drag is hovering this folder as a "drop into" target.
    property bool dropTarget: DesktopStateManager.dragFolderTarget === String(model.inode)

    // Folders keep the plain "folder" theme icon (works reliably); files resolve
    // their MIME/.desktop icon candidate list.
    property string iconImagePath: model.isDir
        ? Quickshell.iconPath("folder", true)
        : DesktopStateManager.resolveIcon(model.iconName)
    // .desktop launchers show their app name without the extension.
    property string displayName: String(model.name).endsWith(".desktop")
        ? String(model.name).slice(0, -8)
        : model.name

    width: 70
    height: content.implicitHeight + 10
    // Drop target (green): a drag is hovering this folder. Otherwise selected
    // (solid highlight + outline) / hover (faint highlight).
    color: dropTarget ? Qt.rgba(0.3, 0.8, 0.45, 0.4)
        : selected ? Qt.rgba(0.47, 0.44, 1, 0.40)
        : mouseArea.containsMouse ? Qt.rgba(0.47, 0.44, 1, 0.15)
        : "transparent"
    radius: 3
    border.width: (selected || dropTarget) ? 1 : 0
    border.color: dropTarget ? Qt.rgba(0.3, 0.8, 0.45, 0.9) : Qt.rgba(0.47, 0.44, 1, 0.7)
    x: model.gridX * DesktopStateManager.cellWidth
    y: model.gridY * DesktopStateManager.cellHeight
    visible: model.screen === screenName
    // Dim the real icon while it's being dragged; the ghost preview stands in.
    opacity: (DesktopStateManager.dragActive && DesktopStateManager.isDraggingInode(String(model.inode))) ? 0.35 : 1.0

    Column {
        id: content
        width: parent.width
        anchors.margins: 4
        spacing: 4

        IconImage {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitSize: 50
            source: rect.iconImagePath
        }

        Text {
            id: label
            width: parent.width
            clip: true
            horizontalAlignment: Text.AlignHCenter
            // Only the selected icon expands to show its full name.
            elide: rect.selected ? Text.ElideNone : Text.ElideRight
            wrapMode: rect.selected ? Text.Wrap : Text.NoWrap
            font.pixelSize: 12
            text: rect.displayName
        }
    }

    // Handles selection + open. Coexists with the DragHandler below: on a plain
    // press/release it emits clicks, but once the pointer moves past the drag
    // threshold the DragHandler steals the grab and starts a drag instead.
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onClicked: mouse => {
            if (mouse.modifiers & Qt.ControlModifier) {
                DesktopStateManager.toggleSelection(model.inode)
            } else {
                DesktopStateManager.selectOnly(model.inode)
            }
        }
        onDoubleClicked: DesktopStateManager.activateIcon(model.inode)
    }

    // Native Qt DnD is used ONLY to route drag events across monitors (each grid
    // window's DropArea receives them). The moving payload travels in the mime
    // data as JSON so the drop is self-contained (independent of when the shared
    // preview state is cleared). No Drag.imageSource is set — the custom ghost
    // preview stands in for it.
    Drag.dragType: Drag.Automatic
    Drag.supportedActions: Qt.MoveAction

    // Cleared only when the whole drag truly ends (dropped or cancelled). We must
    // NOT clear on DragHandler.active going false: during a native drag that fires
    // as soon as the pointer leaves this monitor, which would wipe the preview
    // mid-drag right when it should be hopping to the next screen.
    Drag.onDragFinished: DesktopStateManager.clearDragState()

    DragHandler {
        id: dragger
        target: null

        onActiveChanged: {
            if (active) {
                DesktopStateManager.beginDrag(model.inode, rect.screenName)
                // Populate mime data AFTER beginDrag has built the item list.
                rect.Drag.mimeData = {
                    "application/x-porthole-desktop-icon": JSON.stringify(DesktopStateManager.dragItems)
                }
                rect.Drag.active = true
            } else {
                rect.Drag.active = false
            }
        }
    }
}
