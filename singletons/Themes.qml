pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Font Control
    property string textFont: "Inter"

    // Base colors
    property color primaryColor: activePalette.window
    property color primaryHoverColor: activePalette.highlight
    property color primaryHoverShadow: activePalette.shadow
    property color textColor: activePalette.text
    property color accentColor: activePalette.accent
    property color accentHover: Qt.lighter(activePalette.accent, 1.8)
    property color accentTextColor: themes[currentTheme].accentTextColor

    property color popupBackgroundColor: activePalette.base

    // Utility menu pallet
    property color utilButtonDisabled: disabledPalette.accent
    property color utilButtonBorder: "#3B3B3B"

    property SystemPalette activePalette: SystemPalette {
        colorGroup: SystemPalette.Active
    }

    property SystemPalette disabledPalette: SystemPalette {
        colorGroup: SystemPalette.Disabled
    }
}