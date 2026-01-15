// Bar.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.modules.widgets
import qs.modules.widgets.startwidget
import qs.modules.widgets.openwindowswidget
import qs.modules.systemtray
import qs.modules.notifications
import qs.singletons

Scope {
    NotificationServer{
        id: notificationServer
        
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: (notification) => {
            NotificationManager.addNotification(notification)
            notification.tracked = true
        }
    }
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: root
            required property var modelData
            screen: modelData
            
            WlrLayershell.namespace: "qsBar"
            color: Themes.primaryColor
            
            anchors {
                bottom: true
                left: true
                right: true
            }
            
            implicitHeight: 50
            
            margins {
                top: 0
                left: 0
                right: 0
            }
            
            // Thin border seperator line
            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: 1
                color: Themes.primaryHoverColor
            }
            
            // Main horizontal layout for the taskbar
            RowLayout {
                id: mainRow
                property var topBottomMargins: 3
                height: parent.height
                width: parent.width
                anchors.topMargin: 0
                anchors.bottomMargin: 0
                
                StartButton {
                    implicitWidth: parent.height - (mainRow.topBottomMargins * 2)
                    implicitHeight: parent.height - (mainRow.topBottomMargins * 2)
                    Layout.topMargin: mainRow.topBottomMargins
                    Layout.bottomMargin: mainRow.topBottomMargins
                    Layout.leftMargin: 5
                }

                OpenWindowsScroller{
                    Layout.fillWidth: true
                    Layout.maximumWidth: root.width - rightWidgets.width
                    height: parent.height - (mainRow.topBottomMargins * 2)
                    Layout.topMargin: mainRow.topBottomMargins
                    Layout.bottomMargin: mainRow.topBottomMargins
                }
                
                Item { Layout.fillWidth: true } // spacer
                
                RowLayout {
                    id: rightWidgets
                    height: parent.height - (mainRow.topBottomMargins * 2)
                    Layout.rightMargin: 5
                    Layout.topMargin: mainRow.topBottomMargins
                    Layout.bottomMargin: mainRow.topBottomMargins

                    SystemTrayButton{
                        id: trayButton
                    }
                    UpdateWidget{}
                    QuickSettingsWidget{}
                    ClockWidget {}
                }
                
            }

            Variants {
                model: NotificationManager.visibleNotifications

                NotificationPopup {
                    id: notificationPopup
                }
            }
        }
    }
}
