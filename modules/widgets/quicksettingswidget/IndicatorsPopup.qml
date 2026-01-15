import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.singletons

PopupWindow {
    required property var messageText
    property var margin: 15
    implicitWidth: message.width + margin
    implicitHeight: message.height + margin
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        color: Themes.popupBackgroundColor
        radius: 10

        Text {
            id: message
            anchors.centerIn: parent 
            anchors.margins: 30
            text: messageText
            color: Themes.textColor
            font.pixelSize: 12
        }
    }
}
