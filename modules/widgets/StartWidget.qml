import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.widgets.startwidget
import qs.singletons

Button {
    id: root

    property string imageSource: "root:/assets/archlogo.svg"
    property string alternateImageSource: "root:/assets/toothless.gif"
    property bool menuOpen: false

    contentItem: AnimatedImage {
        id: buttonImage
        anchors.centerIn: parent
        source: root.imageSource
        width: root.imageSize
        height: root.imageSize
        fillMode: Image.PreserveAspectFit
        playing: root.imageSource.endsWith(".gif")
        paused: false
    }

    background: Rectangle {
        color: root.hovered ? Themes.primaryHoverColor : "transparent"
        radius: 6
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

    StartPopup{
        id: popupLoader
    }

    // *** Easter Egg :) ***
    onPressAndHold: {
        holdTimer.start()
    }

    onReleased: {
        holdTimer.stop()
    }

    Timer {
        id: holdTimer
        interval: 5000 
        repeat: false
        onTriggered: {
            var temp = root.imageSource
            root.imageSource = root.alternateImageSource
            root.alternateImageSource = temp
        }
    }
    //*********************
}