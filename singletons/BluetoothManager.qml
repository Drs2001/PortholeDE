pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Singleton {
    id: root

    property var adapter: Bluetooth.defaultAdapter

    // Booleans used for themeing
    property var isEnabled: true
    property var isConnected: false
    
    // Sorted device lists
    property var connectedDevices: adapter?.devices?.values.filter(d => d.connected)
    property var pairedDevices: adapter?.devices?.values.filter(d => d.paired && !d.connected)
    property var avaliableDevices: adapter?.devices?.values.filter(d => !d.paired && !d.connected && d.deviceName)

    // Discovery auto-stops after this long so the radio doesn't scan forever.
    readonly property int discoveryTimeout: 20000

    // Starts discovery and (re)arms the auto-stop countdown. Pressing refresh
    // again while scanning just extends the window.
    function startDiscovery(){
        console.log("[BT] startDiscovery, adapter=", adapter, "discovering=", adapter?.discovering)
        if(adapter && !adapter.discovering){
            adapter.discovering = true
        }
        discoveryTimer.restart()
        console.log("[BT] timer armed, running=", discoveryTimer.running, "interval=", discoveryTimer.interval)
    }

    // Stops discovery if it's running.
    function stopDiscovery(){
        console.log("[BT] stopDiscovery called, discovering(before)=", adapter?.discovering)
        if(adapter && adapter.discovering){
            adapter.discovering = false
        }
        discoveryTimer.stop()
        console.log("[BT] stopDiscovery done, discovering(after)=", adapter?.discovering)
    }

    Timer {
        id: discoveryTimer
        interval: root.discoveryTimeout
        repeat: false
        onTriggered: {
            console.log("[BT] discoveryTimer FIRED")
            root.stopDiscovery()
        }
    }

    // Watch the adapter's discovering state to see if BlueZ flips it back.
    Connections {
        target: root.adapter
        function onDiscoveringChanged() {
            console.log("[BT] discoveringChanged ->", root.adapter?.discovering)
        }
    }

    // Sets the pairability of the bluetooth adapter.(This is needed so that the device can bond to the adapter, otherwise it only soft connects)
    function enablePairable(){
        adapter.pairableTimeout = 10 // set the pairable timeout to ensure it always disables pairing (May update later to manual enable/ disable of pairable)
        adapter.pairable = true
    }

    // Toggle the bluetooth adapter(adapter.state, 0 = Disabled, 1 = Enabled, 4 = Blocked)
    function toggleBluetooth(){
        if(adapter.state == 4){
            bluetoothUnblock.running = true
        }
        else if(adapter.state == 1){
            bluetoothBlock.running = true
        }
        else if(adapter.state == 0){
            adapter.enabled = true
        }
    }

    Process {
        id: bluetoothUnblock
        command: ["rfkill", "unblock", "bluetooth"]
        running: false
    }

    Process {
        id: bluetoothBlock
        command: ["rfkill", "block", "bluetooth"]
        running: false
    }
}