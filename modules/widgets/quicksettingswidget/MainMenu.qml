import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.widgets.quicksettingswidget.bluetooth
import qs.modules.widgets.quicksettingswidget.audiocontrols
import qs.modules.widgets.quicksettingswidget.powerprofiles
import qs.modules.widgets.quicksettingswidget.nightlight
import qs.singletons

Item {
    id: rootMenu
    property var brightness: 1
    property var buttonWidth: 90
    implicitHeight: 300
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Flow {
            id: trayIconsFlow
            Layout.fillWidth: true
            Layout.preferredHeight: rootMenu.height * 0.55
            Layout.leftMargin: 15
            Layout.topMargin: 20
            spacing: 20
            
            // Bluetooth Button
            BTMenuButton{
                stack: rootStack
                buttonWidth: rootMenu.buttonWidth
            }

            // Power profiles switch
            PPMenuButton{
                buttonWidth: rootMenu.buttonWidth
            }

            // Night light toggle
            NightLightButton{
                buttonWidth: rootMenu.buttonWidth
            }
        }

        // Audio Control
        ColumnLayout{
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 10
            Layout.preferredHeight: rootMenu.height * 0.30
            RowLayout{
                spacing: 20
                Button {
                    id: audioToggle
                    background: Rectangle {
                        implicitHeight: 32
                        implicitWidth: 32
                        color: audioToggle.hovered ? Themes.hoverOverlay : "transparent"
                        radius: 5
                    }
                    contentItem: Text {
                        text: AudioManager.volumeIcon
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 16
                        color: Themes.textColor
                    }

                    onClicked: {
                        AudioManager.toggleSinkMute()
                    }
                }
                Slider {
                    id: control
                    from: 0
                    value: AudioManager.volumeLevel
                    to: 1.5
                    stepSize: 0.01

                    background: Rectangle {
                        x: control.leftPadding
                        y: control.topPadding + control.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        width: control.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#bdbebf"

                        Rectangle {
                            width: control.visualPosition * parent.width
                            height: parent.height
                            color: Themes.accentColor
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
                        y: control.topPadding + control.availableHeight / 2 - height / 2
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 13
                        color: control.pressed ? "#f0f0f0" : "#f6f6f6"
                        border.color: "#bdbebf"

                        Popup {
                            id: handlePopup
                            popupType: Popup.Item
                            y: -height - 10
                            x: (parent.width - width) / 2
                            visible: hoverHandler.hovered || control.pressed
                            closePolicy: Popup.NoAutoClose

                            background: Rectangle {
                                implicitWidth: 40
                                implicitHeight: 20
                                color: Themes.primaryColor
                                radius: 5
                            }

                            contentItem: Text {
                                font.family: Themes.textFont
                                horizontalAlignment: Text.AlignHCenter
                                text: Math.round(AudioManager.volumeLevel * 100)
                                color: Themes.textColor
                            }
                        }

                        HoverHandler {
                            id: hoverHandler
                        }
                    }

                    onMoved: {
                        AudioManager.setVolume(control.value)
                    }
                }
                // Bluetooth Button
                AudioMenuButton{
                    stack: rootStack
                }
            }
        }

        // Brightness Control
        ColumnLayout{
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 10
            Layout.preferredHeight: rootMenu.height * 0.30
            RowLayout{
                spacing: 20
                Button {
                    background: Rectangle {
                        implicitHeight: 32
                        implicitWidth: 32
                        color: "transparent"
                        radius: 5
                    }
                    contentItem: Text {
                        text: "\udb81\udda8"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        color: Themes.textColor
                    }
                }
                Slider {
                    id: brightControl
                    from: .1
                    value: rootMenu.brightness
                    to: 1
                    stepSize: 0.01

                    background: Rectangle {
                        x: brightControl.leftPadding
                        y: brightControl.topPadding + brightControl.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        width: brightControl.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#bdbebf"

                        Rectangle {
                            width: brightControl.visualPosition * parent.width
                            height: parent.height
                            color: Themes.accentColor
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: brightControl.leftPadding + brightControl.visualPosition * (brightControl.availableWidth - width)
                        y: brightControl.topPadding + brightControl.availableHeight / 2 - height / 2
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 13
                        color: brightControl.pressed ? "#f0f0f0" : "#f6f6f6"
                        border.color: "#bdbebf"
                    }

                    onMoved: {
                        Quickshell.execDetached({
                            command: ["hyprctl", "hyprsunset", "gamma", (brightControl.value * 100)]
                        });
                    }
                }
            }
        }

        Rectangle {
            id: bottomBar
            Layout.fillWidth: true
            Layout.preferredHeight: rootMenu.height * 0.15
            // Clean W11 footer: no chunky colored bar, just a divider above it.
            color: "transparent"

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color: Themes.dividerColor
            }

            RowLayout{
                anchors.fill: parent
                spacing: 8
                Text {
                    visible: PowerManager.isLaptop
                    Layout.leftMargin: 10
                    Layout.bottomMargin: 4 // Needed to adjust so icon is centered with text, weird icon issue
                    Layout.alignment: Qt.AlignVCenter
                    color: Themes.textColor
                    text: PowerManager.batteryIcon
                    font.pixelSize: 24
                }
                Text {
                    font.family: Themes.textFont
                    visible: PowerManager.isLaptop
                    Layout.alignment: Qt.AlignVCenter
                    color: Themes.textColor
                    text: PowerManager.batteryPercentage + "%"
                    font.pixelSize: 12
                }

                // Spacer
                Item{
                    Layout.fillWidth: true
                }

                Button {
                    id: openSettings
                    Layout.rightMargin: 10
                    background: Rectangle {
                        implicitHeight: 32
                        implicitWidth: 32
                        color: openSettings.hovered ? Themes.hoverOverlay : "transparent"
                        radius: 5
                    }
                    contentItem: Text {
                        text: "\ueb51"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                        color: Themes.textColor
                    }

                    onClicked: {
                        //TODO: Launch settings app once done
                    }
                }
            }
        }

    }

    // Brightness pulling to control brightness slider position
    Process {
        id: gammaProc
        command: ["hyprctl", "hyprsunset", "gamma"]
        running: true

        stdout: StdioCollector {
        onStreamFinished: {
            rootMenu.brightness = parseInt(this.text.trim()) * .01
        }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
        gammaProc.running = true
        }
    }
    
}
