import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.singletons

ColumnLayout{
    required property var stack
    required property var buttonWidth

    Row {
        Layout.alignment: Qt.AlignHCenter
        Button {
            id: wifiToggle
            implicitHeight: buttonWidth / 2
            implicitWidth: buttonWidth / 2

            contentItem: Text{
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "\udb81\udda9"
                color: NetworkManager.wifiEnabled ? Themes.accentTextColor : Themes.textColor
            }

            background: Rectangle{
                radius: 0
                topLeftRadius: 4
                bottomLeftRadius: 4
                color: {
                    if(NetworkManager.wifiEnabled){
                        return wifiToggle.hovered ? Themes.accentHover : Themes.accentColor
                    }
                    else {
                        return wifiToggle.hovered ? Themes.primaryHoverColor : Themes.utilButtonDisabled
                    }
                }
            }

            onClicked: {
                NetworkManager.toggleWifi()
            }
        }
        Button {
            id: wifiOpen
            implicitHeight: buttonWidth / 2
            implicitWidth: buttonWidth / 2

            contentItem: Text{
                font.pixelSize: 15
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "\uf054"
                color: NetworkManager.wifiEnabled ? Themes.accentTextColor : Themes.textColor
            }

            background: Rectangle{
                radius: 0
                topRightRadius: 4
                bottomRightRadius: 4
                color: {
                    if(NetworkManager.wifiEnabled){
                        return wifiOpen.hovered ? Themes.accentHover : Themes.accentColor
                    }
                    else {
                        return wifiOpen.hovered ? Themes.primaryHoverColor : Themes.utilButtonDisabled
                    }
                }
            }

            onClicked: {
                // stack.push("BluetoothMenu.qml", {stack: stack})
                console.log(NetworkManager.wifiEnabled)
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Wifi"
        color: Themes.textColor
    }
}