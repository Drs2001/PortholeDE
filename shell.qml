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
  Bar {}
  AppLauncher{
    id: appMenu
  }
}