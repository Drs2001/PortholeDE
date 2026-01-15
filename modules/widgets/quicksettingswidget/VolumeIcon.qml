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

  IndicatorsPopup{
    id: status
     anchor {
        item: volumeIcon
        rect.x: (volumeIcon.width - width) / 2
        rect.y: -height - 20
    }
    messageText: (AudioManager.sink?.description ?? "No audio") + ": " + AudioManager.volumePercentage
  }
}