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

    property bool hovered: false
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
    color: hovered ? Qt.rgba(0.47, 0.44, 1, 0.33) : "transparent"
    radius: 3
    x: model.gridX * DesktopStateManager.cellWidth
    y: model.gridY * DesktopStateManager.cellHeight
    visible: model.screen === screenName

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
            elide: rect.hovered ? Text.ElideNone : Text.ElideRight
            wrapMode: rect.hovered ? Text.Wrap : Text.NoWrap
            font.pixelSize: 12
            text: rect.displayName
        }
    }

    HoverHandler {
        id: baseHover
        onHoveredChanged: rect.hovered = baseHover.hovered
    }

    // Double-click launches the app / opens the folder / opens the file.
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onDoubleTapped: DesktopStateManager.activateIcon(model.inode)
    }

    Drag.mimeData: {
        "application/x-desktop-icon": String(model.inode)
    }
    Drag.dragType: Drag.Automatic
    Drag.supportedActions: Qt.CopyAction
    Drag.imageSource: rect.iconImagePath
    Drag.imageSourceSize: Qt.size(60, 60)

    DragHandler {
        id: dragger
        target: null

        onActiveChanged: {
            if (active) {
                rect.Drag.active = true
                rect.hovered = true
            } else {
                rect.Drag.active = false
                rect.hovered = false
            }
        }
    }
}
