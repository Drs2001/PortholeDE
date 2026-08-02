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

    // Master switch for the "liquid glass" look (bar + popups). A future UI toggle
    // can just flip this — false makes every glass surface fully solid again.
    property bool glassEnabled: true

    // Bar background. Semi-transparent (when glass is on) so a compositor
    // glass/blur effect (e.g. HyprGlass on the "porthole-bar" namespace) has
    // something to refract through.
    property real barOpacity: 0.55
    property color barColor: glassEnabled
        ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, barOpacity)
        : primaryColor

    // Popup/flyout background. Translucent glass when enabled, solid otherwise.
    property real popupGlassOpacity: 0.62
    property color popupGlassColor: glassEnabled
        ? Qt.rgba(popupBackgroundColor.r, popupBackgroundColor.g, popupBackgroundColor.b, popupGlassOpacity)
        : popupBackgroundColor

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

    // Windows 11 quick-settings tiles: translucent fill when OFF (reads on glass),
    // accent fill when ON (see accentColor/accentHover).
    property color tileInactiveColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.08)
    property color tileInactiveHoverColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.15)

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