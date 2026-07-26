import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.singletons

Item {
    implicitHeight: 640

    // Used to reset the menu view
    function resetMenu() {
        searchBar.focus = false
        searchBar.text = ""
        scroll.ScrollBar.vertical.position = 0
        powerPopup.close()
        ApplicationsManager.updateEntries()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Search pill ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 28
            Layout.leftMargin: 40
            Layout.rightMargin: 40
            Layout.preferredHeight: 40
            radius: height / 2
            color: Themes.subtleOverlay
            border.width: 1
            border.color: Themes.dividerColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: ""   // magnifier (nerd font)
                    color: Themes.mutedTextColor
                    font.pixelSize: 15
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    id: searchBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    leftPadding: 0
                    placeholderText: qsTr("Search for apps")
                    color: Themes.textColor
                    placeholderTextColor: Themes.mutedTextColor
                    font.family: Themes.textFont
                    font.pixelSize: 14
                    background: Rectangle { color: "transparent" }

                    onTextEdited: {
                        ApplicationsManager.updateEntries(searchBar.text)
                    }
                }
            }
        }

        // ── Section header ───────────────────────────────────────────────────
        Text {
            text: "All apps"
            color: Themes.textColor
            font.family: Themes.textFont
            font.pixelSize: 14
            font.bold: true
            Layout.fillWidth: true
            Layout.leftMargin: 40
            Layout.topMargin: 26
            Layout.bottomMargin: 8
        }

        // ── App list ─────────────────────────────────────────────────────────
        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 32
            Layout.rightMargin: 32

            contentWidth: availableWidth
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: parent.width
                spacing: 1

                Repeater {
                    model: ApplicationsManager.entries
                    delegate: ColumnLayout {
                        required property var modelData
                        required property int index
                        spacing: 1
                        Layout.fillWidth: true

                        // Alphabetical divider (accent letter, like Windows 11).
                        Text {
                            visible: index === 0 ||
                                    modelData.name.charAt(0).toUpperCase() !==
                                    ApplicationsManager.entries[index - 1].name.charAt(0).toUpperCase()
                            text: modelData.name.charAt(0).toUpperCase()
                            color: Themes.textColor
                            font.family: Themes.textFont
                            font.pixelSize: 14
                            font.bold: true
                            Layout.leftMargin: 14
                            Layout.topMargin: index === 0 ? 0 : 10
                            Layout.bottomMargin: 2
                            Layout.fillWidth: true
                        }

                        ApplicationButton {
                            application: modelData
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        // ── Footer (account + power) ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: Themes.subtleOverlay
            bottomLeftRadius: 10
            bottomRightRadius: 10

            // Top divider line
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Themes.dividerColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 12

                // Account chip
                Button {
                    id: accountButton
                    Layout.preferredHeight: 44
                    Layout.alignment: Qt.AlignVCenter
                    padding: 6

                    background: Rectangle {
                        color: accountButton.hovered ? Themes.hoverOverlay : "transparent"
                        radius: 6
                    }

                    contentItem: RowLayout {
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 15
                            color: Themes.accentColor

                            Text {
                                anchors.centerIn: parent
                                text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                                color: Themes.accentTextColor
                                font.family: Themes.textFont
                                font.pixelSize: 15
                                font.bold: true
                            }
                        }

                        Text {
                            text: Quickshell.env("USER") || "User"
                            color: Themes.textColor
                            font.family: Themes.textFont
                            font.pixelSize: 14
                            Layout.rightMargin: 6
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Power button
                Button {
                    id: powerMenuButton
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    Layout.alignment: Qt.AlignVCenter

                    contentItem: Text {
                        text: "⏻"
                        color: Themes.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 24
                    }
                    background: Rectangle {
                        color: powerMenuButton.hovered ? Themes.hoverOverlay : "transparent"
                        radius: 6
                    }

                    onClicked: {
                        powerPopup.open()
                    }

                    PowerMenu {
                        id: powerPopup
                    }
                }
            }
        }
    }
}
