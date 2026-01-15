import QtQuick
import Quickshell
import Quickshell.Io
import qs.singletons

Item{
    id: networkIcon
    implicitHeight: networkIconText.height
    implicitWidth: networkIconText.width

    property string networkStatus: "disconnected"
    property string networkName: ""

    function updateNetworkIcon() {
        // Update icon based on network status
        if(networkStatus.includes("ethernet")){
            networkIconText.text = "\udb80\udc02";  // ethernet icon
        }
        else if (networkStatus.includes("wireless")) {
            networkIconText.text = "\udb81\udda9";  // wifi icon
        } 
        else {
            networkIconText.text = "\udb81\uddaa";  // disconnected icon
        }
    }
    Text{
        id: networkIconText
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

    IndicatorsPopup{
        id: status
        anchor {
            item: networkIcon
            rect.x: (networkIcon.width - width) / 2
            rect.y: -height - 20
        }
        messageText: networkName
    }

    Process {
        id: nmcliProc
        command: ["nmcli", "-t", "-f", "STATE,TYPE", "connection", "show", "--active"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                networkIcon.networkStatus = this.text
                updateNetworkIcon()
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

    Component.onCompleted: updateNetworkIcon()
}