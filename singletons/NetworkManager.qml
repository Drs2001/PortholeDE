pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    property var wifiDevice: Networking.devices.values[0]
    property var wifiEnabled: Networking.wifiEnabled

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled
    }
}