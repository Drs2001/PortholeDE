import qs.singletons
import QtQuick
import QtQuick.Controls
import qs.modules.widgets.quicksettingswidget
import Quickshell

Button{
  id: updateButton
  visible: (UpdateListener.base_packages + UpdateListener.aur_packages) > 0

  implicitWidth:32
  implicitHeight: parent.height

  background: Rectangle{
    anchors.fill: parent
    color: updateButton.hovered ? Themes.barHoverColor : "transparent"
    radius: 6
  }
  contentItem: Text{
    id: updateSwirly
    text: "\udb81\udeb0"
    font.pixelSize: 18
    color: Themes.textColor
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  onClicked: {
    //TODO: Once settings/app store is done this should open the update section of the app
  }

  onHoveredChanged: {
    status.visible = updateButton.hovered
  }

  PopupWindow {
    id: status
    property var margin: 15
    anchor {
        item: updateButton
        rect.x: (updateButton.width - width) / 2
        rect.y: -height - 10
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
            text: "Base packages: " + UpdateListener.base_packages + "\n AUR packages: " + UpdateListener.aur_packages
            color: Themes.textColor
            font.pixelSize: 12
        }
    }
  }
}
