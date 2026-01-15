import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.singletons

Item {
    id: bluetoothMenu
    required property var stack
    implicitHeight: 300

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout{
            Layout.fillWidth: true
            Layout.margins: 5
            
            Button {
                id: backButton
                implicitHeight: 32
                implicitWidth: 32

                contentItem: Text{
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "\uf060"
                    color: Themes.textColor
                }

                background: Rectangle{
                    color: backButton.hovered ? Themes.primaryHoverColor : "transparent"
                    border.color: backButton.hovered ? Themes.primaryHoverShadow : "transparent"
                    radius: 6
                }

                onClicked: {
                    stack.pop()
                    
                }
            }
            Text{
                text: "Bluetooth"
                color: Themes.textColor
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
            }

            Item { Layout.fillWidth: true } // spacer

            Switch {
                id: toggleSwitch
                checked: BluetoothManager.adapter.enabled
                onClicked: BluetoothManager.toggleBluetooth()

                indicator: Rectangle{
                    implicitWidth: 48
                    implicitHeight: 26
                    x: toggleSwitch.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 13
                    color: toggleSwitch.checked ? Themes.accentColor: "transparent"
                    border.color: toggleSwitch.checked ? Themes.accentColor : Themes.textColor

                    Rectangle {
                        x: toggleSwitch.checked ? parent.width - width : 0
                        width: 26
                        height: 26
                        radius: 13
                    }
                }
            }
        }

         // Show message when Bluetooth is disabled
        Item {
            visible: !BluetoothManager.adapter.enabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Column{
                anchors.centerIn: parent
                width: parent.width
                spacing: 8
                Text {
                    text: "Bluetooth is off"
                    color: Themes.textColor
                    font.bold: true
                    font.pixelSize: 16
                    leftPadding: 10
                    rightPadding: 10
                }
                Text {
                    text: "Connect to nearby Bluetooth devices by turning on your Bluetooth using the toggle above."
                    color: Themes.textColor
                    font.pixelSize: 12
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: 10
                    rightPadding: 10
                }
            }
        }

        ScrollView {
            id: scroll
            visible: BluetoothManager.adapter.enabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: 10
            Layout.leftMargin: 10
            Layout.bottomMargin: 10

            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 8

                Text {
                    text: "Paired Devices"
                    color: Themes.textColor
                    font.bold: true
                    Layout.fillWidth: true
                }
                Repeater {
                    model: BluetoothManager.connectedDevices
                    delegate: BTDeviceButton{
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }
                Repeater {
                    model: BluetoothManager.pairedDevices
                    delegate: BTDeviceButton{
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: "Avaliable Devices"
                    color: Themes.textColor
                    font.bold: true
                    Layout.fillWidth: true
                }

                Repeater {
                    model: BluetoothManager.avaliableDevices
                    delegate: BTDeviceButton{
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Rectangle {
            id: bottomBar
            Layout.fillWidth: true
            Layout.preferredHeight: bluetoothMenu.height * 0.15
            color: Themes.primaryColor
            bottomLeftRadius: 10
            bottomRightRadius: 10

            RowLayout{
                anchors.fill: parent
                layoutDirection: Qt.RightToLeft
                Button {
                    id: refreshButton
                    implicitHeight: 32
                    implicitWidth: 32
                    Layout.rightMargin: 10

                    contentItem: Text{
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "\udb81\udc50"
                        color: Themes.textColor
                    }

                    background: Rectangle{
                        color: refreshButton.hovered ? Themes.primaryHoverColor : "transparent"
                        border.color: refreshButton.hovered ? Themes.primaryHoverShadow : "transparent"
                        radius: 6
                    }

                    onClicked: {
                        BluetoothManager.startDiscovery()
                    }
                }
            }
        }
    }
}
