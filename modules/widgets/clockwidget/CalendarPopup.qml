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
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]

        anchor.item: clockButton
        anchor.rect.y: -height - 20
        implicitWidth: 320
        implicitHeight: 372
        color: "transparent"

        // Self-contained clock for the header (don't rely on the ClockWidget's id).
        SystemClock {
            id: calClock
            enabled: popup.visible
            precision: SystemClock.Minutes
        }

        Rectangle {
            anchors.fill: parent
            color: Themes.popupBackgroundColor
            radius: 10
            border.width: 1
            border.color: Themes.dividerColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                // ── Current date header ──────────────────────────────────────
                Text {
                    text: Qt.formatDateTime(calClock.date, "dddd, MMMM d")
                    color: Themes.textColor
                    font.family: Themes.textFont
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                // ── Month/year + navigation ──────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: popup.monthNames[popup.month] + " " + popup.year
                        color: Themes.textColor
                        font.family: Themes.textFont
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Button {
                        id: upButton
                        implicitHeight: 28
                        implicitWidth: 28
                        background: Rectangle {
                            color: upButton.hovered ? Themes.hoverOverlay : "transparent"
                            radius: 14
                        }
                        contentItem: Text {
                            text: ""   // caret up (previous month)
                            color: Themes.textColor
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if((popup.month - 1) < 0){
                                popup.month = 11
                                popup.year = popup.year - 1
                            } else {
                                popup.month = popup.month - 1
                            }
                        }
                    }
                    Button {
                        id: downButton
                        implicitHeight: 28
                        implicitWidth: 28
                        background: Rectangle {
                            color: downButton.hovered ? Themes.hoverOverlay : "transparent"
                            radius: 14
                        }
                        contentItem: Text {
                            text: ""   // caret down (next month)
                            color: Themes.textColor
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if((popup.month + 1) > 11){
                                popup.month = 0
                                popup.year = popup.year + 1
                            } else {
                                popup.month = popup.month + 1
                            }
                        }
                    }
                }

                // ── Weekday header ───────────────────────────────────────────
                DayOfWeekRow {
                    id: weekRow
                    locale: Qt.locale("en_US")
                    Layout.fillWidth: true
                    spacing: 0

                    delegate: Text {
                        required property var model
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: model.narrowName
                        font.family: Themes.textFont
                        font.pixelSize: 12
                        color: Themes.mutedTextColor
                    }
                }

                // ── Day grid ─────────────────────────────────────────────────
                MonthGrid {
                    id: grid
                    month: popup.month
                    year: popup.year
                    locale: Qt.locale("en_US")
                    spacing: 2

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    delegate: Item {
                        required property var model

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) - 4
                            height: width
                            radius: width / 2
                            color: model.today ? Themes.accentColor
                                : dayHover.hovered ? Themes.hoverOverlay
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: model.day
                                font.family: Themes.textFont
                                font.pixelSize: 13
                                font.bold: model.today
                                color: model.today ? Themes.accentTextColor
                                    : model.month !== grid.month ? Themes.mutedTextColor
                                    : Themes.textColor
                            }

                            HoverHandler { id: dayHover }
                        }
                    }
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
