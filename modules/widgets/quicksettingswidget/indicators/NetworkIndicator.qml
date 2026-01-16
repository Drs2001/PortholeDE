import QtQuick
import Quickshell
import Quickshell.Io
import qs.singletons

Item{
    id: networkIndicator
    implicitHeight: networkIndicatorText.height
    implicitWidth: networkIndicatorText.width

    property string networkStatus: "disconnected"
    property string networkName: ""

    function updatenetworkIndicator() {
        // Update icon based on network status
        if(networkStatus.includes("ethernet")){
            networkIndicatorText.text = "\udb80\udc02";  // ethernet icon
        }
        else if (networkStatus.includes("wireless")) {
            networkIndicatorText.text = "\udb81\udda9";  // wifi icon
        } 
        else {
            networkIndicatorText.text = "\udb81\uddaa";  // disconnected icon
        }
    }
    Text{
        id: networkIndicatorText
        font.family: "Symbols Nerd Font"
        font.pixelSize: 16
        color: Themes.textColor
        text: "\udb81\uddaa"  
    }

    HoverHandler {
        onHoveredChanged: {
            status.visible = hovered
        }
    }

    PopupWindow {
        id: status
        property var margin: 15
        anchor {
            item: networkIndicator
            rect.x: (networkIndicator.width - width) / 2
            rect.y: -height - 20
        }
        implicitWidth: message.width + margin
        implicitHeight: message.height + margin
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            color: Themes.popupBackgroundColor
            radius: 10

            Text {
                id: message
                anchors.centerIn: parent 
                anchors.margins: 30
                text: networkName
                color: Themes.textColor
                font.pixelSize: 12
            }
        }
    }

    Process {
        id: nmcliProc
        command: ["nmcli", "-t", "-f", "STATE,TYPE", "connection", "show", "--active"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                networkIndicator.networkStatus = this.text
                updatenetworkIndicator()
            }
        }
    }

    Process {
        id: getNetworkName
        command: ["sh", "-c", "nmcli -g GENERAL.CONNECTION device show \"$(nmcli -g DEVICE device status | head -n1)\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                networkName = this.text
            }
        }
    }

    Timer {
        interval: 1000  // Check every 1 seconds
        running: true
        repeat: true
        onTriggered: {
            nmcliProc.running = true
            getNetworkName.running = true
        }
    }

    Component.onCompleted: updatenetworkIndicator()
}