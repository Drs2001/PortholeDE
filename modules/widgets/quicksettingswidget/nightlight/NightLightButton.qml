import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.singletons

ColumnLayout{
    property var isNightLightEnabled: false
    width: 90

    Button {
        id: nightLightToggle
        implicitHeight: 45
        Layout.fillWidth: true

        Layout.alignment: Qt.AlignHCenter

        contentItem: Text{
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "\udb81\udda8"
            color: isNightLightEnabled ? Themes.accentTextColor : Themes.textColor
        }

        background: Rectangle{
            radius: 4
            color: {
                if(isNightLightEnabled){
                    return nightLightToggle.hovered ? Themes.accentHover : Themes.accentColor
                }
                else {
                    return nightLightToggle.hovered ? Themes.primaryHoverColor : Themes.utilButtonDisabled
                }
            }
        }

        onClicked: {
            if(isNightLightEnabled){
                Quickshell.execDetached({
                    command: ["hyprctl", "hyprsunset", "temperature", "6000"]
                });
            }
            else{
                Quickshell.execDetached({
                    command: ["hyprctl", "hyprsunset", "temperature", "2500"]
                });
            }
        }
    }

    Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Night Light"
        color: Themes.textColor
    }

    Process {
        id: temperatureValue
        command: ["hyprctl", "hyprsunset", "temperature"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if(this.text != 6000){
                    isNightLightEnabled = true
                }
                else{
                    isNightLightEnabled = false
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            temperatureValue.running = true
        }
  }
}