import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.singletons

Item {
    required property var application
    implicitHeight: button.implicitHeight  
    implicitWidth: button.implicitWidth    
    
    Button {
        id: button
        width: parent.width

        contentItem: Row{
            spacing: 8

            // Temporary solution for displaying icons, doesnt fully work and some icons look pixelated
            IconImage {
                source: Quickshell.iconPath(application.icon, "application-default-icon")
                implicitSize: 24
            }
            Text{
                text: application.name
                color: Themes.textColor
            }
        }

        background: Rectangle{
            color: button.hovered ? Themes.primaryHoverColor : "transparent"
            border.color: button.hovered ? Themes.primaryHoverShadow : "transparent"
            radius: 6
        }

        onClicked: {
            if(application.runInTerminal){
                Quickshell.execDetached({
                    command: ["kitty", ...application.command],
                    workingDirectory: application.workingDirectory,
                });
            }
            else{
                application.execute()
            }
            popup.visible = false
        }
    }
}