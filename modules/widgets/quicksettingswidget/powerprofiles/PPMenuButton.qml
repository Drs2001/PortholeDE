import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.singletons

ColumnLayout{
    required property var buttonWidth
    width: buttonWidth

    Button {
        id: powerProfilesOpen
        implicitHeight: buttonWidth / 2
        Layout.fillWidth: true

        Layout.alignment: Qt.AlignHCenter

        contentItem: Text{
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "\ueacd"
            color: Themes.accentTextColor
        }

        background: Rectangle{
            radius: 4
            color: powerProfilesOpen.hovered ? Themes.accentHover : Themes.accentColor
        }

        onClicked: {
            var profile = PowerProfiles.profile
            if(profile == 0){
                PowerProfiles.profile = 1
            }
            else if(profile == 1 && PowerProfiles.hasPerformanceProfile){
                PowerProfiles.profile = 2
            }
            else {
                PowerProfiles.profile = 0
            }
        }
    }

    Text {
        font.family: Themes.textFont
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: PowerProfile.toString(PowerProfiles.profile)
        color: Themes.textColor
    }
}