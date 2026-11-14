pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Central icon lookup used by the taskbar, launcher, start menu, notifications,
// volume mixer and desktop icons, so the same app gets the same icon everywhere.
//
// Modeled on how GNOME's window tracker works: first work out WHICH APP owns a
// window (desktop entry), then use that app's Icon=. Guessing from the window's
// app id is only the last resort.
//
// Window -> app, in order:
//   1. Sandbox / launch identity from the window's process (Flatpak app id, or
//      GIO_LAUNCHED_DESKTOP_FILE when it belongs to this exact pid). Reliable.
//   2. DesktopEntries.heuristicLookup(appId) - matches desktop ids, case
//      variants and StartupWMClass.
//   3. The app's systemd scope (app-<launcher>-<desktop-id>...scope), as set by
//      uwsm / GNOME / systemd-run. Only used when 2 fails, because a scope is
//      inherited by anything started from that app (e.g. a terminal).
// App/name -> icon file: see iconPath() and nameCandidates().
Singleton {
    id: root

    // Bumped whenever a lookup could now give a different answer (desktop entries
    // finished loading/changed, a pid hint arrived). Bind to it to re-resolve.
    property int revision: 0

    readonly property string defaultIcon: firstIcon(["application-default-icon", "application-x-executable"])

    // pid -> { flatpak, gio, scope } desktop-id hints ("" when unknown)
    property var pidHints: ({})
    property var pidQueue: []
    property bool pidResolving: false

    // DesktopEntries are loaded asynchronously and are EMPTY right after the shell
    // starts; anything resolved before they arrive must be resolved again.
    // (Entries arrive one change signal at a time, so coalesce them.)
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { revisionTimer.restart() }
    }

    Timer {
        id: revisionTimer
        interval: 50
        onTriggered: root.revision++
    }

    // ── Icon name / path -> image source ────────────────────────────────────

    // Resolves an Icon= style value: theme name, absolute path, file:// URL or a
    // (non-spec but common) name with an extension. Returns "" if nothing exists.
    function iconPath(icon) {
        if (!icon) return ""
        var name = String(icon).trim()
        if (!name) return ""
        if (name.startsWith("image://")) return name
        if (name.startsWith("file://")) name = decodeURIComponent(name.slice(7))

        var p = Quickshell.iconPath(name, true)
        if (p) return p

        // "foo.png" / "foo.svg": try the bare theme name.
        if (!name.startsWith("/")) {
            var bare = name.replace(/\.(png|svg|svgz|xpm)$/i, "")
            if (bare !== name) {
                p = Quickshell.iconPath(bare, true)
                if (p) return p
            }
        }
        return ""
    }

    function firstIcon(names) {
        for (var i = 0; i < names.length; i++) {
            var p = iconPath(names[i])
            if (p) return p
        }
        return ""
    }

    // Icon for a DesktopEntry (launcher / start menu).
    function entryIcon(entry) {
        return (entry && iconPath(entry.icon)) || defaultIcon
    }

    // Icon-name guesses for an app id with no usable desktop entry, most specific
    // first. Case is preserved until the very end - theme lookups are
    // case-sensitive ("org.gnome.Nautilus" != "org.gnome.nautilus").
    function nameCandidates(appId) {
        var out = []
        function add(n) { if (n && out.indexOf(n) === -1) out.push(n) }
        function dashStrip(n) {   // GTK-style: foo-bar-baz -> foo-bar -> foo
            add(n)
            var i
            while ((i = n.lastIndexOf("-")) > 0) {
                n = n.slice(0, i)
                add(n)
            }
        }

        var id = String(appId)
        dashStrip(id)

        // Steam games: steam_app_<n> windows, steam_icon_<n> icons.
        var steam = id.match(/^steam_app_(\d+)$/)
        if (steam) add("steam_icon_" + steam[1])

        // Trailing version numbers: "app-1.2.3", "app_v2" -> "app"
        var unversioned = id.replace(/[-_ ]v?\d+(\.\d+)*$/i, "")
        if (unversioned !== id) dashStrip(unversioned)

        // Reverse-DNS ids: org.foo.Bar -> Bar (after dropping the version, so
        // the dots in "1.2" aren't mistaken for a domain)
        if (unversioned.indexOf(".") !== -1) dashStrip(unversioned.slice(unversioned.lastIndexOf(".") + 1))

        // Lower-case variants last.
        var snapshot = out.slice()
        for (var i = 0; i < snapshot.length; i++) add(snapshot[i].toLowerCase())

        // Chromium-based web apps without their own desktop entry.
        if (/^(chrome|crx_)/i.test(id)) { add("chromium"); add("google-chrome") }
        return out
    }

    // ── Window -> desktop entry ─────────────────────────────────────────────

    function entryForApp(appId, pid) {
        var hint = pid ? pidHints[pid] : undefined
        if (hint) {
            var e = byIdLoose(hint.flatpak) || byIdLoose(hint.gio)
            if (e) return e
        }
        if (appId) {
            var h = DesktopEntries.heuristicLookup(String(appId))
            if (h) return h
        }
        if (hint) return byIdLoose(hint.scope)
        return null
    }

    // byId that tolerates a ".desktop" suffix or a full path.
    function byIdLoose(id) {
        if (!id) return null
        var s = String(id)
        s = s.slice(s.lastIndexOf("/") + 1).replace(/\.desktop$/, "")
        return s ? DesktopEntries.byId(s) : null
    }

    // Icon for an open window. `pid` is optional; when given, the first call
    // starts a background check of the process and bumps `revision` when done.
    function iconForApp(appId, pid) {
        if (pid) requestPidHint(pid)

        var entry = entryForApp(appId, pid)
        if (entry) {
            var p = iconPath(entry.icon)
            if (p) return p
        }
        if (appId) {
            var guessed = firstIcon(nameCandidates(appId))
            if (guessed) return guessed
        }
        return defaultIcon
    }

    // Icon for a notification: its own icon, then the app's desktop entry (the
    // desktop-entry hint, then the app name), then the default.
    function notificationIcon(appIcon, desktopEntry, appName) {
        var p = iconPath(appIcon)
        if (p) return p
        var e = byIdLoose(desktopEntry)
            || (desktopEntry ? DesktopEntries.heuristicLookup(desktopEntry) : null)
            || (appName ? DesktopEntries.heuristicLookup(appName) : null)
        return (e && iconPath(e.icon)) || (appName && firstIcon(nameCandidates(appName))) || defaultIcon
    }

    // Icon for a PipeWire stream from its node properties.
    function streamIcon(props) {
        if (!props) return defaultIcon
        var p = iconPath(props["application.icon-name"])
        if (p) return p
        var keys = ["application.id", "application.process.binary", "application.name"]
        for (var i = 0; i < keys.length; i++) {
            var v = props[keys[i]]
            if (!v) continue
            var e = DesktopEntries.heuristicLookup(String(v))
            if (e && (p = iconPath(e.icon))) return p
        }
        for (var j = 0; j < keys.length; j++) {
            var v2 = props[keys[j]]
            if (v2 && (p = firstIcon(nameCandidates(v2)))) return p
        }
        return defaultIcon
    }

    // ── Process identity (pid -> desktop id hints) ──────────────────────────

    // systemd scope/service -> desktop id. Handles e.g.
    //   app-gnome-org.gnome.Nautilus-1234.scope   -> org.gnome.Nautilus
    //   app-Hyprland-kitty@a1b2c3.service         -> kitty
    //   app-flatpak-org.videolan.VLC-5678.scope   -> org.videolan.VLC
    // Garbage in is fine: the result is only used if byId() finds an entry.
    function desktopIdFromScope(unit) {
        var m = String(unit).match(/^app-(.+)\.(scope|service)$/)
        if (!m) return ""
        var body = m[1].replace(/@[^@]*$/, "").replace(/-[0-9]+$/, "")
        var parts = body.split("-")
        if (parts.length < 2) return ""
        return parts.slice(1).join("-").replace(/\\x2d/g, "-")
    }

    // Drop hints for processes that no longer own a window (pids get reused).
    function prunePids(livePids) {
        var keep = {}
        var changed = false
        for (var pid in pidHints) {
            if (livePids.indexOf(pid) !== -1) keep[pid] = pidHints[pid]
            else changed = true
        }
        if (changed) pidHints = keep
    }

    function requestPidHint(pid) {
        pid = String(pid)
        if (pidHints[pid] !== undefined || pidQueue.indexOf(pid) !== -1) return
        pidQueue.push(pid)
        processNextPid()
    }

    function processNextPid() {
        if (pidResolving || pidQueue.length === 0) return
        pidResolving = true
        pidProc.currentPid = pidQueue.shift()
        pidProc.command = ["sh", "-c", pidScript, "porthole", pidProc.currentPid]
        pidProc.running = true
    }

    readonly property string pidScript: `
        p="$1"
        [ -d "/proc/$p" ] || exit 0
        if [ -r "/proc/$p/root/.flatpak-info" ]; then
            printf 'flatpak|%s\\n' "$(sed -n 's/^name=//p' "/proc/$p/root/.flatpak-info" | head -n1)"
        fi
        env=$(tr '\\0' '\\n' < "/proc/$p/environ" 2>/dev/null)
        gio_pid=$(printf '%s\\n' "$env" | sed -n 's/^GIO_LAUNCHED_DESKTOP_FILE_PID=//p' | head -n1)
        if [ "$gio_pid" = "$p" ]; then
            printf 'gio|%s\\n' "$(printf '%s\\n' "$env" | sed -n 's/^GIO_LAUNCHED_DESKTOP_FILE=//p' | head -n1)"
        fi
        printf 'scope|%s\\n' "$(sed -n 's#.*/##p' "/proc/$p/cgroup" 2>/dev/null | head -n1)"
    `

    Process {
        id: pidProc
        property string currentPid: ""

        stdout: StdioCollector {
            onStreamFinished: {
                var hint = { flatpak: "", gio: "", scope: "" }
                var lines = this.text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var sep = lines[i].indexOf("|")
                    if (sep === -1) continue
                    var key = lines[i].slice(0, sep)
                    var val = lines[i].slice(sep + 1).trim()
                    if (key === "flatpak") hint.flatpak = val
                    else if (key === "gio") hint.gio = val
                    else if (key === "scope") hint.scope = root.desktopIdFromScope(val)
                }

                var hints = Object.assign({}, root.pidHints)
                hints[pidProc.currentPid] = hint
                root.pidHints = hints
                if (hint.flatpak || hint.gio || hint.scope) root.revision++

                root.pidResolving = false
                pidRestartTimer.restart()
            }
        }
    }

    // Small gap so the finished process is torn down before it's reused.
    Timer {
        id: pidRestartTimer
        interval: 10
        onTriggered: root.processNextPid()
    }
}
