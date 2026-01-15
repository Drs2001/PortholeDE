import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
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

  PopupWindow {
    id: status
    property var margin: 15
    anchor {
        item: battery
        rect.x: (battery.width - width) / 2
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
            text: "Battery status: " +  PowerManager.batteryPercentage + "% remaining"
            color: Themes.textColor
            font.pixelSize: 12
        }
    }
  }
}
