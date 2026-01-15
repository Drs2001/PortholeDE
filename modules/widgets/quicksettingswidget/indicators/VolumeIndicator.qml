import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.singletons

Item{
    id: volumeIcon
    implicitHeight: volumeIconText.height
    implicitWidth: volumeIconText.width
    Text {
        id: volumeIconText
        text: AudioManager.volumeIcon
        font.family: "Symbols Nerd Font"
        font.pixelSize: 16
        color: Themes.textColor
    }

    HoverHandler {
        onHoveredChanged: {
        status.visible = hovered
        }
    }

  PopupWindow {
    id: status
    property var margin: 15
    anchor {
        item: volumeIcon
        rect.x: (volumeIcon.width - width) / 2
        rect.y: -height - 20
    }
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
            text: (AudioManager.sink?.description ?? "No audio") + ": " + AudioManager.volumePercentage
            color: Themes.textColor
            font.pixelSize: 12
        }
    }
  }
}