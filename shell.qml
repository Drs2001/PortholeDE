import Quickshell
import Quickshell.Hyprland
import "modules/bar"
import "modules/applauncher"

ShellRoot{
  GlobalShortcut {
      name: "toggle-appmenu"

      onPressed: {
          appMenu.visible = !appMenu.visible
      }
  }
  DesktopGrid{
    barHeight: taskbar.barHeight
  }
  Bar {
    id: taskbar
  }
  AppLauncher{
    id: appMenu
  }
}