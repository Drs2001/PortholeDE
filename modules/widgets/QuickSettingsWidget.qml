import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.modules.widgets.quicksettingswidget
import qs.modules.widgets.quicksettingswidget.indicators
import qs.singletons

Button {
    id: root
    property bool menuOpen: false

    implicitHeight: parent.height

    contentItem: RowLayout{
        spacing: 8
        NetworkIndicator{
            id: networkIndicator
            Layout.alignment: Qt.AlignHCenter
        }
        VolumeIndicator {
            id: volumeIndicator
            Layout.alignment: Qt.AlignHCenter
        }
        BatteryIndicator{
            id: batteryIndicator
            visible: PowerManager.isLaptop
        }
    }

    background: Rectangle {
        color: root.hovered ? Themes.barHoverColor : "transparent"
        radius: 6
    }

    onClicked: {
        if(menuOpen){
            popup.visible = false
        }
        else{
            popup.visible = true
        }
        menuOpen = !menuOpen
    }

    QuickSettingsPopup{
        id: popup
    }
}