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

        // ── Header: back, title, toggle ──────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            spacing: 6

            Button {
                id: backButton
                implicitHeight: 32
                implicitWidth: 32
                contentItem: Text {
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: ""
                    color: Themes.textColor
                }
                background: Rectangle {
                    color: backButton.hovered ? Themes.hoverOverlay : "transparent"
                    radius: 6
                }
                onClicked: stack.pop()
            }

            Text {
                font.family: Themes.textFont
                text: "Bluetooth"
                color: Themes.textColor
                font.pixelSize: 15
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }

            // Windows 11 style toggle.
            Switch {
                id: toggleSwitch
                checked: BluetoothManager.adapter.enabled
                onClicked: BluetoothManager.toggleBluetooth()

                indicator: Rectangle {
                    implicitWidth: 44
                    implicitHeight: 24
                    x: toggleSwitch.width - width - toggleSwitch.rightPadding
                    y: toggleSwitch.topPadding + (toggleSwitch.availableHeight - height) / 2
                    radius: 12
                    color: toggleSwitch.checked ? Themes.accentColor : "transparent"
                    border.width: 2
                    border.color: toggleSwitch.checked ? Themes.accentColor : Themes.mutedTextColor

                    Rectangle {
                        x: toggleSwitch.checked ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: toggleSwitch.checked ? Themes.accentTextColor : Themes.mutedTextColor
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // ── Off state ────────────────────────────────────────────────────────
        Item {
            visible: !BluetoothManager.adapter.enabled
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 10

                Text {
                    text: "󰂲"   // mdi bluetooth-off
                    font.pixelSize: 44
                    color: Themes.mutedTextColor
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    font.family: Themes.textFont
                    text: "Bluetooth is off"
                    color: Themes.textColor
                    font.bold: true
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    font.family: Themes.textFont
                    text: "Turn on Bluetooth with the toggle above to connect to nearby devices."
                    color: Themes.mutedTextColor
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ── Device list ──────────────────────────────────────────────────────
        ScrollView {
            id: scroll
            visible: BluetoothManager.adapter.enabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: 8
            Layout.leftMargin: 8

            contentWidth: availableWidth
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: parent.width
                spacing: 4

                Text {
                    visible: (BluetoothManager.connectedDevices?.length || 0) > 0
                             || (BluetoothManager.pairedDevices?.length || 0) > 0
                    font.family: Themes.textFont
                    text: "Your devices"
                    color: Themes.mutedTextColor
                    font.pixelSize: 12
                    font.bold: true
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.leftMargin: 4
                }
                Repeater {
                    model: BluetoothManager.connectedDevices
                    delegate: BTDeviceButton {
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }
                Repeater {
                    model: BluetoothManager.pairedDevices
                    delegate: BTDeviceButton {
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }

                Text {
                    visible: (BluetoothManager.avaliableDevices?.length || 0) > 0
                    font.family: Themes.textFont
                    text: "Available devices"
                    color: Themes.mutedTextColor
                    font.pixelSize: 12
                    font.bold: true
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.leftMargin: 4
                }
                Repeater {
                    model: BluetoothManager.avaliableDevices
                    delegate: BTDeviceButton {
                        required property var modelData
                        device: modelData
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // ── Footer: scan status + refresh ────────────────────────────────────
        Rectangle {
            id: bottomBar
            visible: BluetoothManager.adapter.enabled
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: "transparent"

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: Themes.dividerColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    font.family: Themes.textFont
                    visible: BluetoothManager.adapter.discovering
                    text: "Scanning…"
                    color: Themes.mutedTextColor
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Button {
                    id: refreshButton
                    implicitHeight: 32
                    implicitWidth: 32
                    contentItem: Text {
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "󰑐"   // mdi refresh
                        color: Themes.textColor
                    }
                    background: Rectangle {
                        color: refreshButton.hovered ? Themes.hoverOverlay : "transparent"
                        radius: 6
                    }
                    onClicked: BluetoothManager.startDiscovery()
                }
            }
        }
    }
}
