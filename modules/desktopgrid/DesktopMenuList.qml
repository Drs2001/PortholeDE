import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.singletons

// Background + list of entries for DesktopContextMenu (used for both the
// menu and its submenu). Hover/click are forwarded to `owner`.
Rectangle {
    id: list

    required property var owner
    property var entries: []
    property bool inSubmenu: false
    // Children list of the submenu currently open (keeps its parent lit).
    property var openChildren: null
    readonly property int padding: 6

    implicitHeight: column.implicitHeight + padding * 2
    color: Themes.popupBackgroundColor
    radius: 8
    border.width: 1
    border.color: Themes.dividerColor

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: list.padding
        spacing: 2

        Repeater {
            model: list.entries

            delegate: Rectangle {
                id: entry
                required property var modelData
                readonly property bool isSeparator: !!modelData.separator
                readonly property bool isEnabled: !isSeparator && modelData.enabled !== false
                readonly property bool hasChildren: !!modelData.children

                Layout.fillWidth: true
                implicitHeight: isSeparator ? 9 : 30
                radius: 5
                color: isEnabled && (hover.hovered || (hasChildren && list.openChildren === modelData.children))
                    ? Themes.hoverOverlay : "transparent"

                Rectangle {
                    visible: entry.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: 1
                    color: Themes.dividerColor
                }

                RowLayout {
                    visible: !entry.isSeparator
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10
                    opacity: entry.isEnabled ? 1 : 0.45

                    // Fixed-width slot so labels line up with or without an icon.
                    Item {
                        implicitWidth: 16
                        implicitHeight: 16
                        IconImage {
                            anchors.fill: parent
                            visible: source != ""
                            source: entry.modelData.icon ? IconResolver.iconPath(entry.modelData.icon) : ""
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: entry.modelData.text || ""
                        color: Themes.textColor
                        font.family: Themes.textFont
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: entry.hasChildren
                        text: "›"
                        color: Themes.mutedTextColor
                        font.family: Themes.textFont
                        font.pixelSize: 16
                    }
                }

                HoverHandler {
                    id: hover
                    enabled: entry.isEnabled
                    onHoveredChanged: if (hovered) list.owner.entryHovered(entry, list.inSubmenu)
                }

                TapHandler {
                    enabled: entry.isEnabled
                    onTapped: list.owner.entryClicked(entry, list.inSubmenu)
                }
            }
        }
    }
}
