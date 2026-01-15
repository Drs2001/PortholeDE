import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.singletons

ColumnLayout{
    required property var stack

    Row {
        Layout.alignment: Qt.AlignHCenter
        Button {
            id: bluetoothToggle
            implicitHeight: 45
            implicitWidth: 45

            contentItem: Text{
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "\udb80\udcaf"
                color: BluetoothManager.adapter?.enabled ? Themes.accentTextColor : Themes.textColor
            }

            background: Rectangle{
                radius: 0
                topLeftRadius: 4
                bottomLeftRadius: 4
                color: {
                    if(BluetoothManager.adapter){
                        if(BluetoothManager.adapter.enabled){
                            return bluetoothToggle.hovered ? Themes.accentHover : Themes.accentColor
                        }
                        else {
                            return bluetoothToggle.hovered ? Themes.primaryHoverColor : Themes.utilButtonDisabled
                        }
                    }
                    else{
                        return Themes.accentColor
                    }
                }
            }

            onClicked: {
                BluetoothManager.toggleBluetooth()
            }
        }
        Button {
            id: bluetoothOpen
            implicitHeight: 45
            implicitWidth: 45

            contentItem: Text{
                font.pixelSize: 15
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "\uf054"
                color: BluetoothManager.adapter?.enabled ? Themes.accentTextColor : Themes.textColor
            }

            background: Rectangle{
                radius: 0
                topRightRadius: 4
                bottomRightRadius: 4
                color: {
                    if(BluetoothManager.adapter){
                        if(BluetoothManager.adapter.enabled){
                            return bluetoothOpen.hovered ? Themes.accentHover : Themes.accentColor
                        }
                        else {
                            return bluetoothOpen.hovered ? Themes.primaryHoverColor : Themes.utilButtonDisabled
                        }
                    }
                    else{
                        return Themes.accentColor
                    }
                }
            }

            onClicked: {
                stack.push("BluetoothMenu.qml", {stack: stack}) // Push files as QML wraps files as components
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Bluetooth"
        color: Themes.textColor
    }
}