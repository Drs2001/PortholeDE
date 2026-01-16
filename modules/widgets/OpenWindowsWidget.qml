import QtQuick
import Quickshell
import qs.modules.widgets.openwindowswidget
import qs.singletons

ListView {
    id: windowScroller
    orientation: ListView.Horizontal

    model: ApplicationsManager.windowKeys
    boundsBehavior: Flickable.StopAtBounds
    delegate: WindowButton {
        required property string modelData
        property var windowInfo: ApplicationsManager.openWindows[modelData]
    }

    WindowPopupView {
        id: windowPopup
        anchor.item: windowScroller
    }
}