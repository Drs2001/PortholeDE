import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.singletons

Popup {
    id: powerMenu
    popupType: Popup.Item

    width: 210
    padding: 6

    // Open above the button and right-align to it, so the flyout never spills
    // past the right edge of the start menu.
    y: -height - 8
    x: parent.width - width

    background: Rectangle {
        color: Themes.popupBackgroundColor
        border.color: Themes.dividerColor
        border.width: 1
        radius: 8
    }

    contentItem: ColumnLayout {
        spacing: 2

        // A single Windows 11 style row: glyph + label, subtle rounded hover.
        component PowerRow: Button {
            id: rowButton
            property string glyph: ""
            property string label: ""

            Layout.fillWidth: true
            Layout.preferredHeight: 40
            padding: 0

            background: Rectangle {
                color: rowButton.hovered ? Themes.hoverOverlay : "transparent"
                radius: 5
            }

            contentItem: Item {
                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 14

                    Text {
                        text: rowButton.glyph
                        color: Themes.textColor
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 20
                    }
                    Text {
                        text: rowButton.label
                        color: Themes.textColor
                        font.family: Themes.textFont
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }

        PowerRow {
            glyph: "󰖔"   // mdi weather-night (moon)
            label: "Sleep"
            onClicked: Quickshell.execDetached({ command: ["systemctl", "suspend"] })
        }
        PowerRow {
            glyph: "󰐥"   // mdi power
            label: "Shut down"
            onClicked: Quickshell.execDetached({ command: ["systemctl", "poweroff"] })
        }
        PowerRow {
            glyph: "󰑙"   // mdi restart
            label: "Restart"
            onClicked: Quickshell.execDetached({ command: ["systemctl", "reboot"] })
        }
    }
}
