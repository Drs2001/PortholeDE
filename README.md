## Description
The desktop environment for Porthole, my custom Linux distribution built on Arch. Since this is built in Quickshell and meant for Hyprland, this desktop environment can be run separately from Porthole. Simply follow the installation instructions below.

![](preview.png)
[![Check out the full video preview!](https://img.youtube.com/vi/9_UvfRMzVjI/0.jpg)](https://www.youtube.com/watch?v=9_UvfRMzVjI)

## Features
- **Taskbar** on every monitor with a start menu, open-window list with live previews (including restoring minimized windows), system tray, update indicator, quick settings and a clock/calendar
- **Start menu** with app search, alphabetical app list and power options (log out, shut down, restart)
- **App launcher** popup toggled with a global shortcut
- **Quick settings**: volume and per-app volume mixer, output device selection, Bluetooth device management, power profiles, night light and screen gamma
- **Desktop icons** for `~/Desktop`: drag and drop (including across monitors), multi-select with Ctrl+click or a selection box, drop files into folders, and positions remembered between sessions
- **Notifications** popup
- **Wallpaper** drawn by Quickshell itself (no hyprpaper needed)
- **Liquid glass** style translucent bar that works with compositor blur effects

## Dependencies
Package names are for Arch Linux (AUR packages marked).

**Core**
- `quickshell` (AUR)
- `hyprland`
- `uwsm` (used by "Log out")

**Fonts**
- `inter-font`
- `ttf-nerd-fonts-symbols`

**Services**
- `pipewire` and `wireplumber` (audio, `wpctl`)
- `bluez` (Bluetooth)
- `networkmanager` (network indicator, `nmcli`)
- `upower` (battery)
- `power-profiles-daemon`
- `hyprsunset` (night light and gamma)

**Desktop icons**
- `inotify-tools` (watches `~/Desktop`)
- `glib2` (`gio`, for file icons and launching `.desktop` files)
- `xdg-utils` (`xdg-open`)
- `nautilus` (opens folders)

**Other**
- `yay` (AUR update count)
- `kitty` (terminal for apps that run in a terminal)

## Install steps
1. Install the dependencies above using your favorite package manager
2. Clone the repo (or download the zip and extract it) into `~/.config/quickshell/porthole`
3. Put a wallpaper at `~/.config/porthole/wallpapers/spring.jpg` (or change the path in `singletons/WallpaperManager.qml`)
4. Launch with `quickshell --config porthole`

To start it with Hyprland, add this to your Hyprland config:
```
exec-once = quickshell --config porthole
```

## Hyprland setup
**App launcher shortcut:** the launcher listens for the global shortcut `toggle-appmenu`. Bind it to a key, for example:
```
bind = SUPER, SPACE, global, quickshell:toggle-appmenu
```

**Minimized windows:** the taskbar treats windows on the `special:minimized` workspace as minimized and moves them back to the current workspace when you click their preview. Add a bind to send windows there, for example:
```
bind = SUPER, M, movetoworkspacesilent, special:minimized
```

**Glass / blur:** the bar uses the layer namespace `porthole-bar` and the wallpaper uses `porthole-wallpaper`, so compositor effects (such as blur or HyprGlass) can target them with layer rules.
