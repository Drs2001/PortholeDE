import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.singletons

LazyLoader {
    loading: true

    PopupWindow {
        id: popup
        property var month: new Date().getMonth()
        property var year: new Date().getFullYear()
        property var monthNames: [
            "January", "Febuary", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]

        anchor.item: clockButton
        anchor.rect.y: -height - 20
        implicitWidth: 300
        implicitHeight: 400
        color: "transparent"

        Rectangle {
            id: trayBackground
            anchors.fill: parent
            color: Themes.popupBackgroundColor
            radius: 10

            ColumnLayout {
                anchors.fill: parent
                Rectangle {
                    id: topBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: popup.height * 0.10
                    color: Themes.primaryColor
                    topLeftRadius: 10
                    topRightRadius: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        text: Time.todaysDate
                        font.pixelSize: 14
                        color: Themes.textColor
                    }
                }
                RowLayout{
                    Layout.fillWidth: true
                    Layout.margins: 10

                    Text{
                        text: monthNames[month] + " " + year
                        color: Themes.textColor
                    }
                    // Spacer
                    Item {
                        Layout.fillWidth: true
                    }
                    Button{
                        id: upButton
                        implicitHeight: 24
                        implicitWidth: 24
                        background: Rectangle {
                            color: upButton.hovered ? Themes.primaryHoverColor : "transparent"
                            radius: 5
                        }
                        contentItem: Text {
                            text: "\uf0d8"
                            color: Themes.textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            if((month - 1) < 0){
                                month = 11
                                year = year - 1
                            }
                            else {
                                month = month - 1
                            }
                        }
                    }
                    Button{
                        id: downButton
                        implicitHeight: 24
                        implicitWidth: 24
                        background: Rectangle {
                            color: downButton.hovered ? Themes.primaryHoverColor : "transparent"
                            radius: 5
                        }
                        contentItem: Text {
                            text: "\uf0d7"
                            color: Themes.textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            if((month + 1) > 11){
                                month = 0
                                year = year + 1
                            }
                            else {
                                month = month + 1
                            }
                        }
                    }
                }
                GridLayout {
                    id: calendar
                    Layout.fillWidth: true
                    columns: 1

                    DayOfWeekRow {
                        locale: Qt.locale("en_US")
                        Layout.fillWidth: true

                        delegate: Text {
                            required property var model
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: model.shortName
                            font.pixelSize: 14
                            color: Themes.textColor
                        }
                    }

                    MonthGrid {
                        id: grid
                        month: popup.month
                        year: popup.year
                        locale: Qt.locale("en_US")

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        delegate: Rectangle {
                            required property var model
                            color: model.today ? Themes.accentColor : "transparent"
                            radius: 20

                            Text {
                                anchors.centerIn: parent
                                text: model.day
                                font.pixelSize: 12
                                font.bold: model.today
                                color: {
                                    if (model.today) return Themes.accentTextColor 
                                    if (model.month !== grid.month) return Themes.primaryHoverColor
                                    return Themes.textColor
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    id: bottomBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: popup.height * 0.10
                    color: Themes.primaryColor
                    bottomLeftRadius: 10
                    bottomRightRadius: 10
                }
            }
            
        }

        onVisibleChanged: {
            if(visible){
                popup.month = new Date().getMonth()
                popup.year = new Date().getFullYear()
                grabTimer.start()
            }
            else{
                menuOpen = false
            }
        }

        // Add a small delay to allow wayland to finish mapping the popupwindow
        // (Don't love this solution and will try to find a better one later)
        Timer {
            id: grabTimer
            interval: 100
            onTriggered: {
                grab.active = true
            }
        }

        // Give focus to popup window to allow for keyboard inputs and clicking off detection
        HyprlandFocusGrab {
            id: grab
            windows: [ popup ]

            onCleared: {
                popup.visible = false
            }
        }
    }
}
