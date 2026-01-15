import qs.singletons
import QtQuick
import QtQuick.Controls
import Quickshell

Button{
  id: updateButton
  visible: (UpdateListener.base_packages + UpdateListener.aur_packages) > 0

  implicitWidth:32
  implicitHeight: parent.height

  background: Rectangle{
    anchors.fill: parent
    color: updateButton.hovered ? Themes.primaryHoverColor : "transparent"
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

  IndicatorsPopup{
    id: status
    anchor {
        item: updateButton
        rect.x: (updateButton.width - width) / 2
        rect.y: -height - 10
    }
    messageText: "Base packages: " + UpdateListener.base_packages + "\n AUR packages: " + UpdateListener.aur_packages
  }
}
