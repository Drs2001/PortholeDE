import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.singletons

Item {
    required property var application
    implicitHeight: 44
    implicitWidth: button.implicitWidth

    Button {
        id: button
        width: parent.width
        height: parent.height
        padding: 0

        contentItem: Item {
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 14

                IconImage {
                    source: Quickshell.iconPath(application.icon, "application-default-icon")
                    implicitSize: 26
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                }
                Text {
                    text: application.name
                    color: Themes.textColor
                    font.family: Themes.textFont
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        background: Rectangle {
            color: button.down ? Themes.pressOverlay
                : button.hovered ? Themes.hoverOverlay
                : "transparent"
            radius: 5
        }

        onClicked: {
            if(application.runInTerminal){
                Quickshell.execDetached({
                    command: ["kitty", ...application.command],
                    workingDirectory: application.workingDirectory,
                });
            }
            else{
                application.execute()
            }
            popup.visible = false
        }
    }
}
