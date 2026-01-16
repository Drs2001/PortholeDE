import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.singletons

Item {
    id: audioMenu
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
                text: "Sound Output"
                color: Themes.textColor
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
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
                    text: "Output Devices"
                    color: Themes.textColor
                    font.bold: true
                    Layout.fillWidth: true
                }
                Repeater {
                    model: AudioManager.sinks
                    delegate: Button{
                        id: sinkButton
                        required property var modelData
                        Layout.fillWidth: true
                        text: modelData.description

                        contentItem: Text {
                            text: modelData.description
                            color: Themes.textColor
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight 
                        }

                        background: Rectangle{
                            color: ((modelData.id == AudioManager.sink.id) || sinkButton.hovered) ? Themes.primaryHoverColor : "transparent"
                            radius: 8
                        }

                        onClicked: {
                            AudioManager.setDefaultSink(modelData)
                        }
                    }
                }
                Text {
                    text: "Volume Mixer"
                    color: Themes.textColor
                    font.bold: true
                    Layout.fillWidth: true
                }
                Repeater {
                    model: AudioManager.outputPrograms
                    delegate: RowLayout{
                        required property var modelData
                        Layout.fillWidth: true

                        Button{
                            id: applicationToggle
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            background: Rectangle{
                                color: applicationToggle.hovered ? Themes.primaryHoverColor : "transparent"
                                radius: 5
                            }
                            contentItem: Item {
                                anchors.fill: parent
                                Image {
                                    height: 26
                                    width: 26
                                    anchors.centerIn: parent
                                    fillMode: Image.PreserveAspectFit
                                    source: Quickshell.iconPath(modelData.properties["application.icon-name"] || "application-menu", true)
                                }
                                Text {
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    text: "X"
                                    color: "red"
                                    font.pixelSize: 10
                                    font.bold: true
                                    visible: modelData.audio.muted
                                }
                            }

                            onClicked: {
                                modelData.audio.muted = !modelData.audio.muted
                            }
                        }
                        Slider {
                            id: control
                            from: 0
                            value: modelData.audio.volume
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
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Math.round(modelData.audio.volume * 100)
                                        color: Themes.textColor
                                    }
                                }

                                HoverHandler {
                                    id: hoverHandler
                                }
                            }

                            onMoved: {
                                modelData.audio.muted = false
                                modelData.audio.volume = control.value
                            }
                        }

                    } 
                }
            }
        }

        Rectangle {
            id: bottomBar
            Layout.fillWidth: true
            Layout.preferredHeight: audioMenu.height * 0.15
            color: Themes.primaryColor
            bottomLeftRadius: 10
            bottomRightRadius: 10
        }
    }
}
