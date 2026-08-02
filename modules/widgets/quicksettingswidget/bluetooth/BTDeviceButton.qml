import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.singletons

Item {
    id: deviceRoot
    required property var device
    property bool expanded: false
    property bool connecting: false

    width: parent.width
    implicitHeight: column.implicitHeight

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    function statusText() {
        if (device.connected) return "Connected"
        if (connecting) return "Connecting…"
        if (device.paired) return "Paired"
        return "Not connected"
    }

    // Maps a BlueZ device.icon name to a nerd-font (MDI) device glyph.
    function deviceGlyph(iconName) {
        var n = (iconName || "").toLowerCase()
        if (n.indexOf("headset") !== -1) return "\uee59"     // headset
        if (n.indexOf("headphone") !== -1) return "\uf025"   // headphones
        if (n.indexOf("speaker") !== -1 || n.indexOf("audio") !== -1) return String.fromCodePoint(0xF04C3) // speaker
        if (n.indexOf("mouse") !== -1) return String.fromCodePoint(0xF037D)       // mouse
        if (n.indexOf("keyboard") !== -1) return String.fromCodePoint(0xF030C)    // keyboard
        if (n.indexOf("gaming") !== -1 || n.indexOf("gamepad") !== -1 || n.indexOf("joystick") !== -1) return String.fromCodePoint(0xF0302) // gamepad
        if (n.indexOf("phone") !== -1) return String.fromCodePoint(0xF011C)       // cellphone
        if (n.indexOf("computer") !== -1 || n.indexOf("laptop") !== -1) return String.fromCodePoint(0xF0322) // laptop
        return String.fromCodePoint(0xF00AF)                                       // bluetooth (default)
    }

    // Mirrors PowerManager's laptop-battery mapping — MDI battery glyphs by level.
    function batteryGlyph(pct) {
        if (pct >= 90) return "󰁹"
        if (pct >= 80) return "󰂂"
        if (pct >= 70) return "󰂁"
        if (pct >= 60) return "󰂀"
        if (pct >= 50) return "󰁿"
        if (pct >= 40) return "󰁾"
        if (pct >= 30) return "󰁽"
        if (pct >= 20) return "󰁼"
        if (pct >= 10) return "󰁻"
        return "󰁺"
    }

    Column {
        id: column
        width: parent.width

        // ── Device row: icon | name + status | battery ───────────────────────
        Button {
            id: deviceButton
            width: parent.width
            implicitHeight: 54
            padding: 0
            onClicked: expanded = !expanded

            background: Rectangle {
                color: deviceButton.hovered ? Themes.hoverOverlay : "transparent"
                radius: 6
            }

            contentItem: Item {
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    // Device-type icon (headset, mouse, keyboard, phone…) as a
                    // nerd-font glyph. Use the symbols font EXPLICITLY: several of
                    // these MDI codepoints are also (badly) claimed by Cardo, and
                    // relying on fallback let fontconfig pick Cardo's broken glyph.
                    Text {
                        text: deviceRoot.deviceGlyph(device.icon)
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 24
                        color: Themes.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Layout.preferredWidth: 30
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: device.deviceName
                            color: Themes.textColor
                            font.family: Themes.textFont
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: deviceRoot.statusText()
                            color: device.connected ? Themes.accentColor : Themes.mutedTextColor
                            font.family: Themes.textFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Battery indicator (only when a level is reported) — MDI
                    // battery glyph + percentage, same approach as the laptop
                    // battery in BatteryIndicator.qml.
                    RowLayout {
                        visible: device.batteryAvailable
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: deviceRoot.batteryGlyph(Math.round(device.battery * 100))
                            font.family: Themes.textFont
                            font.pixelSize: 20
                            color: Themes.textColor
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: Math.round(device.battery * 100) + "%"
                            color: Themes.textColor
                            font.family: Themes.textFont
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }
        }

        // ── Revealer: Connect / Disconnect / Forget ──────────────────────────
        Item {
            id: revealer
            width: parent.width
            height: expanded ? actions.implicitHeight + 8 : 0
            clip: true

            Behavior on height {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            opacity: expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            RowLayout {
                id: actions
                layoutDirection: Qt.RightToLeft
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 2
                spacing: 8

                // Primary action pill (accent) — connect / disconnect.
                Button {
                    id: connectButton
                    implicitHeight: 30
                    leftPadding: 16
                    rightPadding: 16
                    onClicked: {
                        if (device.connected) {
                            device.disconnect()
                        } else {
                            if (!device.paired) BluetoothManager.enablePairable()
                            device.connect()
                        }
                    }
                    contentItem: Text {
                        text: device.connected ? "Disconnect" : "Connect"
                        font.family: Themes.textFont
                        font.pixelSize: 13
                        color: device.connected ? Themes.textColor : Themes.accentTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6
                        color: device.connected
                            ? (connectButton.hovered ? Themes.tileInactiveHoverColor : Themes.tileInactiveColor)
                            : (connectButton.hovered ? Themes.accentHover : Themes.accentColor)
                    }
                }

                // Secondary pill — forget a paired device.
                Button {
                    id: removeButton
                    visible: device.paired
                    implicitHeight: 30
                    leftPadding: 16
                    rightPadding: 16
                    onClicked: device.forget()
                    contentItem: Text {
                        text: "Forget"
                        font.family: Themes.textFont
                        font.pixelSize: 13
                        color: Themes.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6
                        color: removeButton.hovered ? Themes.tileInactiveHoverColor : Themes.tileInactiveColor
                    }
                }
            }
        }

        // Set adapter pairable to false and trust device after pairing
        Connections {
            target: device
            function onPairedChanged() {
                if (!device.trusted && device.paired) {
                    device.trusted = true
                }
            }

            function onStateChanged() {
                var state = device.state.toString()
                if (state == "0") {
                    connecting = false
                } else if (state == "1") {
                    connecting = false
                } else if (state == "2") {
                    //Do nothing for now
                } else if (state == "3") {
                    connecting = true
                }
            }
        }
    }
}
