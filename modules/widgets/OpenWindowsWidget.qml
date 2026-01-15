import QtQuick
import Quickshell
import qs.modules.widgets.openwindowswidget
import qs.singletons

ListView {
    id: windowScroller
    orientation: ListView.Horizontal

    model: WindowManager.windowKeys
    boundsBehavior: Flickable.StopAtBounds
    delegate: WindowButton {
        required property string modelData
        property var windowInfo: WindowManager.openWindows[modelData]
    }

    WindowPopupView {
        id: windowPopup
        anchor.item: windowScroller
    }
}