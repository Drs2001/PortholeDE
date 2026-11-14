import QtQuick
import QtQuick.Controls
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

    // Right-click; x/y are in grid-window coordinates.
    signal contextMenuRequested(real x, real y, string inode)

    // Showing the inline rename field instead of the label.
    readonly property bool renaming: DesktopStateManager.renamingInode === String(model.inode)
        && model.screen === screenName

    onRenamingChanged: {
        if (renaming) {
            renameField.text = DesktopStateManager.renameDraft
            renameField.hadFocus = false
            // Wait for the context menu (and its focus grab) to close first.
            renameFocusTimer.restart()
        }
    }

    Timer {
        id: renameFocusTimer
        interval: 80
        onTriggered: {
            if (!rect.renaming) return
            renameField.forceActiveFocus()
            // Like file managers: preselect the name without its extension.
            var n = renameField.text
            var dot = n.lastIndexOf(".")
            renameField.select(0, (!model.isDir && dot > 0) ? dot : n.length)
        }
    }

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
    // The rename box can grow down over the icon below; keep it on top.
    z: renaming ? 10 : 0
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
            font.family: Themes.textFont
            id: label
            width: parent.width
            clip: true
            horizontalAlignment: Text.AlignHCenter
            // Only the selected icon expands to show its full name.
            elide: rect.selected ? Text.ElideNone : Text.ElideRight
            wrapMode: rect.selected ? Text.Wrap : Text.NoWrap
            font.pixelSize: 12
            text: rect.displayName
            visible: !rect.renaming
        }

        // Inline rename, Windows style: an edit box exactly where the label
        // was, the same width as the icon, wrapping onto more lines (and
        // growing downward) for long names. Enter saves instead of adding a
        // line break. The full filename (with extension) is edited.
        TextArea {
            id: renameField
            visible: rect.renaming
            width: parent.width
            font.family: Themes.textFont
            font.pixelSize: 12
            horizontalAlignment: TextEdit.AlignHCenter
            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
            color: Themes.textColor
            selectionColor: Themes.accentColor
            selectedTextColor: Themes.accentTextColor
            selectByMouse: true
            padding: 2

            readonly property string error: rect.renaming ? DesktopStateManager.renameError(text) : ""

            // Like clicking away in a file manager: losing focus (clicking
            // another app or monitor) saves the rename. No HyprlandFocusGrab
            // here - while one is active Hyprland ignores this window's cursor
            // changes, so the I-beam never showed.
            property bool hadFocus: false
            onActiveFocusChanged: {
                if (activeFocus) hadFocus = true
                else if (hadFocus && rect.renaming) DesktopStateManager.commitRename()
            }

            // No fill or outline: the icon's selection highlight shows through,
            // so the box blends in. A red outline appears only for invalid names.
            background: Rectangle {
                color: "transparent"
                border.width: renameField.error ? 1 : 0
                border.color: renameField.error ? "#e5534b" : Themes.mutedTextColor
            }

            onTextChanged: {
                if (!rect.renaming) return
                // Filenames are one line: drop line breaks (e.g. from a paste).
                if (/[\r\n]/.test(text)) {
                    var pos = cursorPosition
                    text = text.replace(/[\r\n]+/g, "")
                    cursorPosition = Math.min(pos, text.length)
                }
                DesktopStateManager.renameDraft = text
            }
            Keys.onReturnPressed: event => {
                event.accepted = true
                if (!error) DesktopStateManager.commitRename()
            }
            Keys.onEnterPressed: event => {
                event.accepted = true
                if (!error) DesktopStateManager.commitRename()
            }
            Keys.onEscapePressed: DesktopStateManager.cancelRename()

            // Text-selection (I-beam) pointer while hovering the box. Takes no
            // buttons, so clicks/drags still go to the text for selection.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
            }

            ToolTip.visible: rect.renaming && error !== ""
            ToolTip.text: error
        }
    }

    // Handles selection + open. Coexists with the DragHandler below: on a plain
    // press/release it emits clicks, but once the pointer moves past the drag
    // threshold the DragHandler steals the grab and starts a drag instead.
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        // Out of the way while renaming, so clicks reach the rename field and
        // its I-beam cursor applies. (Only disabling it isn't enough: Qt still
        // uses a disabled item's cursorShape, and this sits above the field.)
        enabled: !rect.renaming
        visible: !rect.renaming
        cursorShape: Qt.PointingHandCursor

        // Clicking another icon finishes a rename in progress.
        onPressed: if (DesktopStateManager.renamingInode) DesktopStateManager.commitRename()

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                // Like a file manager: right-clicking inside the selection keeps
                // it (so the menu acts on all of it), otherwise this icon
                // becomes the selection.
                if (!DesktopStateManager.isSelected(model.inode)) {
                    DesktopStateManager.selectOnly(model.inode)
                }
                var p = rect.mapToItem(null, mouse.x, mouse.y)
                rect.contextMenuRequested(p.x, p.y, String(model.inode))
                return
            }
            if (mouse.modifiers & Qt.ControlModifier) {
                DesktopStateManager.toggleSelection(model.inode)
            } else {
                DesktopStateManager.selectOnly(model.inode)
            }
        }
        onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) DesktopStateManager.activateIcon(model.inode)
        }
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
        enabled: !rect.renaming

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
