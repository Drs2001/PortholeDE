import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.singletons

// Small right-click menu for the desktop grid. Each grid window owns one; the
// caller sets anchor.window and calls openAt() with window-local coordinates.
//
// items: [{ text, icon, action, enabled, children }] or { separator: true }
//   icon     - optional theme icon name
//   action   - string passed to triggered() when the item is clicked
//   enabled  - optional, defaults to true
//   children - optional item list; shown as a submenu on hover (one level deep)
PopupWindow {
    id: menu

    property var items: []
    signal triggered(string action)

    implicitWidth: 220
    implicitHeight: mainList.implicitHeight
    color: "transparent"

    // Opens with its top-left corner at (x, y) in the anchor window. The
    // compositor flips/slides it if that would put it off-screen.
    function openAt(x, y, menuItems) {
        visible = false   // re-anchor if it's already open somewhere else
        items = menuItems
        anchor.rect.x = x
        anchor.rect.y = y
        visible = true
    }

    function dismiss() {
        visible = false
    }

    function activate(item) {
        visible = false
        triggered(item.action)
    }

    // Called by entries in either list when hovered or clicked.
    function entryHovered(entry, inSubmenu) {
        if (inSubmenu) return
        if (entry.modelData.children) openSubmenu(entry)
        else submenu.visible = false
    }

    function entryClicked(entry, inSubmenu) {
        if (!inSubmenu && entry.modelData.children) openSubmenu(entry)
        else activate(entry.modelData)
    }

    // Opens the submenu beside `entry` (flipped to the left near the screen edge).
    function openSubmenu(entry) {
        if (submenu.visible && submenu.items === entry.modelData.children) return
        submenu.visible = false
        var p = entry.mapToItem(null, 0, 0)
        submenu.anchor.rect.x = p.x
        // Shift up by the list padding so the first child lines up with `entry`.
        submenu.anchor.rect.y = p.y - mainList.padding
        submenu.anchor.rect.width = entry.width
        submenu.anchor.rect.height = entry.height
        submenu.parentText = entry.modelData.text
        submenu.items = entry.modelData.children
        submenu.visible = true
    }

    // Items can be replaced while open (async results such as Open With apps);
    // keep an open submenu showing its parent's new children.
    onItemsChanged: {
        if (!submenu.visible) return
        for (var i = 0; i < items.length; i++) {
            if (items[i].children && items[i].text === submenu.parentText) {
                submenu.items = items[i].children
                return
            }
        }
        submenu.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            grabTimer.restart()
        } else {
            grab.active = false
            submenu.visible = false
        }
    }

    // Same Wayland mapping race as the bar popups: wait a moment before grabbing.
    Timer {
        id: grabTimer
        interval: 50
        onTriggered: grab.active = true
    }

    // Clicking anywhere outside the menu (or its submenu) closes it.
    HyprlandFocusGrab {
        id: grab
        windows: [ menu, submenu ]
        onCleared: menu.visible = false
    }

    DesktopMenuList {
        id: mainList
        anchors.fill: parent
        owner: menu
        entries: menu.items
        openChildren: submenu.visible ? submenu.items : null

        focus: true
        Keys.onEscapePressed: menu.dismiss()
    }

    PopupWindow {
        id: submenu
        property var items: []
        property string parentText: ""

        anchor.window: menu
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right

        implicitWidth: 200
        implicitHeight: subList.implicitHeight
        color: "transparent"

        DesktopMenuList {
            id: subList
            anchors.fill: parent
            owner: menu
            inSubmenu: true
            entries: submenu.items
        }
    }
}
