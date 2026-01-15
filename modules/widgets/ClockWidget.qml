import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.widgets.clockwidget
import qs.singletons

Button{
  id: clockButton
  property bool menuOpen: false

  implicitHeight: parent.height

  background: Rectangle {
    color: clockButton.hovered ? Themes.primaryHoverColor : "transparent"
    radius: 5
  }
  contentItem: Text {
      text: Time.time + Time.date
      color: Themes.textColor
      font.family: Themes.textFont
      font.pixelSize: 14
      horizontalAlignment: Text.AlignRight
      verticalAlignment: Text.AlignVCenter
    }
  

  onClicked: {
      if(menuOpen){
          popupLoader.item.visible = false
      }
      else{
          popupLoader.item.visible = true
      }
      menuOpen = !menuOpen
  }

  CalendarPopup {
    id: popupLoader
  }
}
