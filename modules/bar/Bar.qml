// Bar.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.modules.widgets
import qs.modules.notifications
import qs.singletons

Scope {
    property int barHeight: 50
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

            // Distinct layer namespace so a compositor effect can target just the
            // bar (e.g. HyprGlass: layers:namespaces = porthole-bar).
            WlrLayershell.namespace: "porthole-bar"

            // Semi-transparent so the glass/blur effect has something to work on.
            // Tune via Themes.barOpacity (1.0 = solid).
            color: Themes.barColor

            anchors {
                bottom: true
                left: true
                right: true
            }
            
            implicitHeight: barHeight
            
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
                
                StartWidget {
                    implicitWidth: parent.height - (mainRow.topBottomMargins * 2)
                    implicitHeight: parent.height - (mainRow.topBottomMargins * 2)
                    Layout.topMargin: mainRow.topBottomMargins
                    Layout.bottomMargin: mainRow.topBottomMargins
                    Layout.leftMargin: 5
                }

                OpenWindowsWidget{
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

                    SystemTrayWidget{
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
