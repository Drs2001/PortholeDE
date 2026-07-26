import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.singletons

PanelWindow {
    id: notiPopup
    required property var modelData

    screen: root.modelData
    visible: true
    color: "transparent"

    anchors {
        bottom: true
        right: true
    }

    implicitWidth: 340
    // Round to a whole pixel: a fractional height puts the bottom-anchored
    // surface on a sub-pixel boundary, which makes the whole popup look blurry.
    implicitHeight: Math.round(bodyColumn.implicitHeight)

    margins {
        bottom: 20
        right: 20
    }

    Rectangle {
        id: contentRect
        anchors.fill: parent
        color: Themes.primaryColor
        radius: 10

        ColumnLayout {
            id: bodyColumn
            anchors.fill: parent
            spacing: 0

            // ── Header: app icon, name, close ────────────────────────────────
            RowLayout {
                id: topRow
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.leftMargin: 8
                Layout.topMargin: 6
                Layout.rightMargin: 6
                spacing: 8

                IconImage {
                    implicitSize: 22
                    source: Quickshell.iconPath(modelData.icon, "application-default-icon")
                }
                Text {
                    text: modelData.appName
                    color: Themes.textColor
                    font.family: Themes.textFont
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Button {
                    id: closeNoti
                    implicitWidth: 20
                    implicitHeight: 20
                    Layout.alignment: Qt.AlignVCenter

                    background: Rectangle {
                        color: closeNoti.hovered ? "red" : "transparent"
                        radius: 5
                    }
                    contentItem: Text {
                        text: "󰅚"   // mdi close (matches taskbar window previews)
                        color: Themes.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        NotificationManager.updateVisibleNotification()
                    }
                }
            }

            // ── Body: optional image + message ───────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.bottomMargin: 10
                Layout.topMargin: 2
                spacing: 10

                Image {
                    visible: modelData.image != ""
                    Layout.preferredHeight: 48
                    Layout.preferredWidth: 48
                    Layout.alignment: Qt.AlignTop
                    source: modelData.image
                    sourceSize: Qt.size(96, 96)   // render at 2x for a crisp downscale
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
                Text {
                    Layout.fillWidth: true
                    text: modelData.body
                    color: Themes.textColor
                    font.family: Themes.textFont
                    // Wrap within the fixed width (breaks long unbroken strings too)
                    // and cap the height so a huge message can't grow off screen.
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    elide: Text.ElideRight
                }
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: 5000
        onTriggered: {
            NotificationManager.updateVisibleNotification()
        }
    }

    Component.onCompleted: {
        dismissTimer.start()
    }
}
