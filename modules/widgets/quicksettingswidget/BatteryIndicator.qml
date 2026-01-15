import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.singletons

RowLayout {
  id: battery
  Text {
    text: PowerManager.batteryIcon
    color: Themes.textColor
    font.family: Themes.textFont
    font.pixelSize: 20
  }
  Text {
    visible: false //Removing visibility for now but will eventually want this controllable from settings
    text: PowerManager.batteryPercentage
    color: Themes.textColor
    font.family: Themes.textFont
    font.pixelSize: 12
  }

  HoverHandler {
    onHoveredChanged: {
      status.visible = hovered
    }
  }

  IndicatorsPopup{
    id: status
     anchor {
        item: battery
        rect.x: (battery.width - width) / 2
        rect.y: -height - 20
    }
    messageText: "Battery status: " +  PowerManager.batteryPercentage + "% remaining"
  }
}
