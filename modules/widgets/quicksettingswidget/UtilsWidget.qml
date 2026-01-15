import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.singletons

Button {
    id: root
    property bool menuOpen: false

    implicitHeight: parent.height

    contentItem: RowLayout{
        spacing: 8
        NetworkIcon{
            id: networkIcon
            Layout.alignment: Qt.AlignHCenter
        }
        VolumeIcon {
            id: volumeIcon
            Layout.alignment: Qt.AlignHCenter
        }
        BatteryIndicator{
            id: batteryIndicator
            visible: PowerManager.isLaptop
        }
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

    UtilsPopup{
        id: popupLoader
    }
}