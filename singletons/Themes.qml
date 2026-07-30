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
    property color accentTextColor: '#000000'

    property color popupBackgroundColor: activePalette.base

    // Bar background. Kept semi-transparent so a compositor glass/blur effect
    // (e.g. HyprGlass on the "porthole-bar" layer namespace) has something to
    // refract through. Set barOpacity to 1.0 for a fully solid bar.
    property real barOpacity: 0.55
    property color barColor: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, barOpacity)

    // Hover fill for bar widgets. A translucent light overlay (derived from the
    // text color, so it adapts to light/dark) reads as part of the glass, unlike
    // a solid highlight which looks pasted on. Tune the alpha to taste.
    property color barHoverColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.10)

    // Subtle text-derived overlays (adapt to light/dark palettes) for Windows 11
    // style hover fills, input backgrounds and divider lines.
    property color hoverOverlay: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.09)
    property color pressOverlay: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.14)
    property color subtleOverlay: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.05)
    property color dividerColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.12)
    property color mutedTextColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.6)

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