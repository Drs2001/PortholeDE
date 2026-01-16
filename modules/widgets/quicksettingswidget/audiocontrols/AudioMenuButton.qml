import QtQuick
import QtQuick.Controls
import Quickshell
import qs.singletons

Button {
    required property var stack
    id: openAudioMenu
    implicitWidth: 30
    implicitHeight: 30

    contentItem: Text{
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "\uf054"
        color: Themes.textColor
    }

    background: Rectangle{
        color: openAudioMenu.hovered ? Themes.primaryHoverColor : "transparent"
        radius: 6
    }

    onClicked: {
        stack.push("AudioMenu.qml", {stack: stack}) // Push files as QML wraps files as components
    }
}