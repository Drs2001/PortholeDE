import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import qs.singletons

Button {
    id: button
    property var minimized: false

    implicitWidth: windowScroller.height
    implicitHeight: windowScroller.height

    contentItem: Image{
        source: windowInfo.iconPath
        sourceSize.width: button.width
        sourceSize.height: button.height
        fillMode: Image.PreserveAspectFit
    }

    background: Rectangle{
        color: button.hovered ? Themes.barHoverColor  : "transparent"
        radius: 6
    }

    onHoveredChanged: {
        if(button.hovered){
            showTimer.restart()
        }
        else{
            hideTimer.restart()
        }
    }

    Timer {
        id: showTimer
        interval: 200
        onTriggered: {
            hideTimer.stop()
            windowPopup.show(button, windowInfo.addresses)
        }
    }

    Timer {
        id: hideTimer
        interval: 10
        onTriggered: {
            showTimer.stop()
            windowPopup.hide()
        }
    }

    onClicked: {
    }
}
