pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Caelestia.I18n
import Caelestia.Services
import qs.components.misc

Singleton {
    id: root

    readonly property bool isNiri: Boolean(Quickshell.env("NIRI_SOCKET"))

    // Niri state
    property var niriRawWorkspaces: []
    property var niriRawWindows: []
    property var niriFocusedWindowObj: null
    property int niriActiveWorkspaceId: 1
    property string niriCurrentKbLayout: "??"
    property string niriCurrentKbLayoutFull: "??"

    readonly property var niriWorkspacesList: {
        const wins = niriWindowsList;
        const res = [];
        for (const ws of niriRawWorkspaces) {
            const toplevelsList = wins.filter(t => t.workspace && t.workspace.id === ws.idx);
            res.push({
                id: ws.idx,
                idx: ws.idx,
                name: ws.name ? ws.name : String(ws.idx),
                monitor: root.monitorFor(null),
                output: ws.output,
                is_active: ws.is_active,
                is_focused: ws.is_focused,
                lastIpcObject: {
                    windows: toplevelsList.length,
                    specialWorkspace: { name: "" }
                },
                toplevels: {
                    values: toplevelsList
                }
            });
        }
        return res;
    }

    readonly property var niriWindowsList: {
        return niriRawWindows.map(w => {
            const wsObj = niriRawWorkspaces.find(ws => ws.id === w.workspace_id);
            const wsIdx = wsObj ? wsObj.idx : w.workspace_id;
            return {
                id: w.id,
                address: "0x" + w.id.toString(16),
                title: w.title || "",
                workspace: {
                    id: wsIdx,
                    idx: wsIdx,
                    name: wsObj && wsObj.name ? wsObj.name : String(wsIdx)
                },
                lastIpcObject: {
                    class: w.app_id || w.title || "unknown",
                    title: w.title || "",
                    fullscreen: w.is_focused && w.is_fullscreen ? 2 : 0,
                    floating: w.is_floating || false,
                    mapped: true
                }
            };
        });
    }

    readonly property var toplevels: isNiri ? ({ values: niriWindowsList }) : Hyprland.toplevels
    readonly property var workspaces: isNiri ? ({ values: niriWorkspacesList }) : Hyprland.workspaces
    readonly property var monitors: isNiri ? ({ values: [monitorFor(null)] }) : Hyprland.monitors
    readonly property bool usingLua: isNiri ? false : Hyprland.usingLua

    readonly property var activeToplevel: {
        if (isNiri)
            return niriFocusedWindowObj;
        const t = Hyprland.activeToplevel;
        return t?.workspace?.name.startsWith("special:") || Hyprland.focusedWorkspace?.toplevels.values.length > 0 ? t : null;
    }
    readonly property var focusedWorkspace: {
        if (isNiri) {
            const toplevelsList = toplevelsForWs(activeWsId);
            return {
                id: activeWsId,
                idx: activeWsId,
                name: String(activeWsId),
                lastIpcObject: { windows: toplevelsList.length },
                toplevels: { values: toplevelsList }
            };
        }
        return Hyprland.focusedWorkspace;
    }
    readonly property var focusedMonitor: {
        if (isNiri) {
            const screen = Quickshell.screens[0];
            return monitorFor(screen);
        }
        return Hyprland.focusedMonitor;
    }
    readonly property int activeWsId: isNiri ? niriActiveWorkspaceId : (focusedWorkspace?.id ?? 1)

    readonly property HyprKeyboard keyboard: isNiri ? null : (extras.devices.keyboards.find(kb => kb.main) ?? null)
    readonly property bool capsLock: isNiri ? false : (keyboard?.capsLock ?? false)
    readonly property bool numLock: isNiri ? false : (keyboard?.numLock ?? false)
    readonly property string defaultKbLayout: isNiri ? niriCurrentKbLayout : (keyboard?.layout.split(",")[0] ?? "??")
    readonly property string kbLayoutFull: isNiri ? niriCurrentKbLayoutFull : (keyboard?.activeKeymap ?? Tr.trCtx("Unknown", "keyboard layout"))
    readonly property string kbLayout: isNiri ? niriCurrentKbLayout : (kbMap.get(kbLayoutFull) ?? "??")
    readonly property var kbMap: new Map()

    readonly property alias extras: extras
    readonly property alias options: extras.options
    readonly property alias devices: extras.devices

    property string lastSpecialWorkspace: ""

    signal configReloaded

    Process {
        id: niriAction
    }

    Process {
        id: niriInitWorkspaces
        command: ["niri", "msg", "-j", "workspaces"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const ws = JSON.parse(text.trim());
                        root.updateNiriWorkspaces(ws);
                    } catch (e) {}
                }
            }
        }
    }

    Process {
        id: niriInitWindows
        command: ["niri", "msg", "-j", "windows"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const wins = JSON.parse(text.trim());
                        root.updateNiriWindows(wins);
                    } catch (e) {}
                }
            }
        }
    }

    Process {
        id: niriInitFocusedWindow
        command: ["niri", "msg", "-j", "focused-window"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const win = JSON.parse(text.trim());
                        if (win && win.id) {
                            root.setNiriFocusedWindow(win);
                        }
                    } catch (e) {}
                }
            }
        }
    }

    Process {
        id: niriInitKb
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const kb = JSON.parse(text.trim());
                        root.updateNiriKb(kb);
                    } catch (e) {}
                }
            }
        }
    }

    Timer {
        id: niriRestartTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (root.isNiri && !niriStream.running) {
                niriStream.running = true;
            }
        }
    }

    Process {
        id: niriStream
        command: ["niri", "msg", "-j", "event-stream"]
        running: root.isNiri
        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim());
                    root.handleNiriEvent(event);
                } catch(e) {}
            }
        }
        onExited: exitCode => {
            if (root.isNiri) {
                niriRestartTimer.restart();
            }
        }
    }

    function initNiriData(): void {
        if (!isNiri) return;
        niriInitWorkspaces.running = true;
        niriInitWindows.running = true;
        niriInitFocusedWindow.running = true;
        niriInitKb.running = true;
    }

    function updateNiriWorkspaces(workspacesList: var): void {
        niriRawWorkspaces = workspacesList.slice().sort((a, b) => a.idx - b.idx);
        const focused = niriRawWorkspaces.find(w => w.is_focused || w.is_active);
        if (focused) {
            niriActiveWorkspaceId = focused.idx;
        }
        const focusedWin = niriRawWindows.find(w => w.is_focused);
        if (focusedWin) {
            setNiriFocusedWindow(focusedWin);
        }
    }

    function updateNiriWindows(windowsList: var): void {
        niriRawWindows = windowsList.slice();
        const focused = niriRawWindows.find(w => w.is_focused);
        if (focused) {
            setNiriFocusedWindow(focused);
        }
    }

    function setNiriFocusedWindow(win: var): void {
        if (!win) {
            niriFocusedWindowObj = null;
            return;
        }
        const wsObj = niriRawWorkspaces.find(ws => ws.id === win.workspace_id);
        const wsIdx = wsObj ? wsObj.idx : win.workspace_id;
        niriFocusedWindowObj = {
            id: win.id,
            address: "0x" + win.id.toString(16),
            title: win.title || "",
            workspace: {
                id: wsIdx,
                idx: wsIdx,
                name: wsObj && wsObj.name ? wsObj.name : String(wsIdx)
            },
            lastIpcObject: {
                class: win.app_id || win.title || "unknown",
                title: win.title || "",
                fullscreen: win.is_focused && win.is_fullscreen ? 2 : 0,
                floating: win.is_floating || false,
                mapped: true
            }
        };
    }

    function updateNiriKb(kbData: var): void {
        if (kbData && kbData.names && kbData.names.length > 0) {
            const idx = kbData.current_idx ?? 0;
            const full = kbData.names[idx] || kbData.names[0];
            niriCurrentKbLayoutFull = full;
            const match = full.match(/\((.*?)\)/);
            niriCurrentKbLayout = match ? match[1].toLowerCase() : full.slice(0, 2).toLowerCase();
        }
    }

    function handleNiriEvent(event: var): void {
        if (event.WorkspacesChanged) {
            updateNiriWorkspaces(event.WorkspacesChanged.workspaces);
        } else if (event.WorkspaceActivated) {
            let matchedIdx = -1;
            for (let i = 0; i < niriRawWorkspaces.length; i++) {
                if (niriRawWorkspaces[i].id === event.WorkspaceActivated.id) {
                    matchedIdx = niriRawWorkspaces[i].idx;
                    niriRawWorkspaces[i].is_focused = true;
                    niriRawWorkspaces[i].is_active = true;
                } else {
                    niriRawWorkspaces[i].is_focused = false;
                    niriRawWorkspaces[i].is_active = false;
                }
            }
            if (matchedIdx !== -1) {
                niriActiveWorkspaceId = matchedIdx;
            } else {
                niriInitWorkspaces.running = false;
                niriInitWorkspaces.running = true;
            }
            niriRawWorkspaces = niriRawWorkspaces.slice();
        } else if (event.WindowsChanged) {
            updateNiriWindows(event.WindowsChanged.windows);
        } else if (event.WindowFocusChanged) {
            const winId = event.WindowFocusChanged.id;
            for (let i = 0; i < niriRawWindows.length; i++) {
                niriRawWindows[i].is_focused = (niriRawWindows[i].id === winId);
            }
            niriRawWindows = niriRawWindows.slice();
            const win = niriRawWindows.find(w => w.id === winId);
            if (win) {
                setNiriFocusedWindow(win);
                const wsObj = niriRawWorkspaces.find(ws => ws.id === win.workspace_id);
                if (wsObj) {
                    niriActiveWorkspaceId = wsObj.idx;
                    for (let i = 0; i < niriRawWorkspaces.length; i++) {
                        niriRawWorkspaces[i].is_focused = (niriRawWorkspaces[i].id === wsObj.id);
                        niriRawWorkspaces[i].is_active = (niriRawWorkspaces[i].id === wsObj.id);
                    }
                    niriRawWorkspaces = niriRawWorkspaces.slice();
                }
            } else if (winId === null || winId === undefined) {
                niriFocusedWindowObj = null;
            }
        } else if (event.WindowOpenedOrChanged) {
            const win = event.WindowOpenedOrChanged.window;
            const idx = niriRawWindows.findIndex(w => w.id === win.id);
            if (idx >= 0) {
                niriRawWindows[idx] = win;
            } else {
                niriRawWindows.push(win);
            }
            niriRawWindows = niriRawWindows.slice();
            if (win.is_focused) {
                setNiriFocusedWindow(win);
            }
        } else if (event.WindowClosed) {
            const winId = event.WindowClosed.id;
            niriRawWindows = niriRawWindows.filter(w => w.id !== winId);
            if (niriFocusedWindowObj && niriFocusedWindowObj.id === winId) {
                niriFocusedWindowObj = null;
            }
        } else if (event.KeyboardLayoutsChanged) {
            updateNiriKb(event.KeyboardLayoutsChanged.keyboard_layouts);
        }
    }

    function dispatch(request: string): void {
        if (isNiri) {
            if (request === "focus-workspace-down" || request === "workspace r+1" || request === "workspace +1") {
                niriAction.running = false;
                niriAction.command = ["niri", "msg", "action", "focus-workspace-down"];
                niriAction.running = true;
            } else if (request === "focus-workspace-up" || request === "workspace r-1" || request === "workspace -1") {
                niriAction.running = false;
                niriAction.command = ["niri", "msg", "action", "focus-workspace-up"];
                niriAction.running = true;
            } else if (request.startsWith("focus-workspace ")) {
                niriAction.running = false;
                niriAction.command = ["niri", "msg", "action", "focus-workspace", request.split(" ")[1]];
                niriAction.running = true;
            } else if (request.startsWith("workspace ")) {
                const arg = request.split(" ")[1];
                if (arg === "r+1" || arg === "+1") {
                    niriAction.running = false;
                    niriAction.command = ["niri", "msg", "action", "focus-workspace-down"];
                    niriAction.running = true;
                } else if (arg === "r-1" || arg === "-1") {
                    niriAction.running = false;
                    niriAction.command = ["niri", "msg", "action", "focus-workspace-up"];
                    niriAction.running = true;
                } else {
                    niriAction.running = false;
                    niriAction.command = ["niri", "msg", "action", "focus-workspace", arg];
                    niriAction.running = true;
                }
            } else if (request.startsWith("movetoworkspace ")) {
                const parts = request.slice("movetoworkspace ".length).split(",");
                const targetWs = parts[0].trim();
                const cmd = ["niri", "msg", "action", "move-window-to-workspace"];
                if (parts.length > 1 && parts[1].includes("address:0x")) {
                    const winId = parseInt(parts[1].split("address:0x")[1], 16);
                    if (!isNaN(winId)) {
                        cmd.push("--window-id", String(winId));
                    }
                }
                cmd.push(targetWs);
                niriAction.running = false;
                niriAction.command = cmd;
                niriAction.running = true;
            } else if (request.startsWith("move-window-to-workspace ") || request.startsWith("move-column-to-workspace ")) {
                const parts = request.split(" ");
                niriAction.running = false;
                niriAction.command = ["niri", "msg", "action", parts[0], parts[1]];
                niriAction.running = true;
            }
            return;
        }
        Hyprland.dispatch(request);
    }

    function focusWorkspace(ws: var): void {
        if (isNiri) {
            const target = (typeof ws === "object" && ws !== null) ? (ws.idx ?? ws.id ?? ws.name) : ws;
            niriAction.running = false;
            niriAction.command = ["niri", "msg", "action", "focus-workspace", String(target)];
            niriAction.running = true;
            return;
        }
        const target = (typeof ws === "object" && ws !== null) ? (ws.name ?? ws.id) : ws;
        dispatch(usingLua ? `hl.dsp.focus({ workspace = "${target}" })` : `workspace ${target}`);
    }

    function toggleSpecial(name: string): void {
        if (isNiri) return;
        dispatch(usingLua ? `hl.dsp.workspace.toggle_special("${name}")` : `togglespecialworkspace ${name}`);
    }

    function cycleSpecialWorkspace(direction: string): void {
        if (isNiri) return;
        const openSpecials = workspaces.values.filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0);

        if (openSpecials.length === 0)
            return;

        const activeSpecial = focusedMonitor.lastIpcObject.specialWorkspace.name ?? "";

        if (!activeSpecial) {
            if (lastSpecialWorkspace) {
                const workspace = workspaces.values.find(w => w.name === lastSpecialWorkspace);
                if (workspace && workspace.lastIpcObject.windows > 0) {
                    focusWorkspace(lastSpecialWorkspace);
                    return;
                }
            }
            focusWorkspace(openSpecials[0].name);
            return;
        }

        const currentIndex = openSpecials.findIndex(w => w.name === activeSpecial);
        let nextIndex = 0;

        if (currentIndex !== -1) {
            if (direction === "next")
                nextIndex = (currentIndex + 1) % openSpecials.length;
            else
                nextIndex = (currentIndex - 1 + openSpecials.length) % openSpecials.length;
        }

        focusWorkspace(openSpecials[nextIndex].name);
    }

    function monitorNames(): list<string> {
        return monitors.values.map(e => e.name);
    }

    function monitorFor(screen: ShellScreen): var {
        if (isNiri) {
            return {
                name: screen ? screen.name : "eDP-1",
                id: 0,
                focused: true,
                activeWorkspace: focusedWorkspace,
                lastIpcObject: { specialWorkspace: { name: "" } }
            };
        }
        return Hyprland.monitorFor(screen);
    }

    function trimWsName(name: string): string {
        return name && name.startsWith("special:") ? name.slice("special:".length) : (name || "");
    }

    function toplevelsForWs(ws: int, ignoredTags = []): var {
        if (isNiri) {
            return niriWindowsList.filter(t => t.workspace && (t.workspace.id === ws || t.workspace.name === String(ws)) && !isToplevelIgnored(t, ignoredTags));
        }
        return toplevels.values.filter(t => t.workspace && t.workspace.id === ws && !isToplevelIgnored(t, ignoredTags));
    }

    function isToplevelIgnored(toplevel: var, ignoredTags = []): bool {
        const ipc = toplevel?.lastIpcObject;
        if (!ipc?.class || !ipc.mapped)
            return true;

        return ipc.tags?.some(tag => ignoredTags.includes(tag.replace(/\*$/, ""))) ?? false;
    }

    function reloadDynamicConfs(): void {
        if (isNiri) return;
        if (usingLua) {
            extras.batchMessage(['eval hl.bind("Caps_Lock", hl.dsp.global("caelestia:refreshDevices"), { locked = true, non_consuming = true, ignore_mods = true, release = true })', 'eval hl.bind("Num_Lock", hl.dsp.global("caelestia:refreshDevices"), { locked = true, non_consuming = true, ignore_mods = true, release = true })']);
        } else {
            extras.batchMessage(["keyword bindlni ,Caps_Lock,global,caelestia:refreshDevices", "keyword bindlni ,Num_Lock,global,caelestia:refreshDevices"]);
        }
    }

    onUsingLuaChanged: reloadDynamicConfs()
    Component.onCompleted: {
        reloadDynamicConfs();
        initNiriData();
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (n === "configreloaded") {
                root.configReloaded();
                root.reloadDynamicConfs();
            } else if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
                Hyprland.refreshToplevels();
            }
        }

        target: root.isNiri ? null : Hyprland
    }

    Connections {
        function onLastIpcObjectChanged(): void {
            if (root.isNiri) return;
            const specialName = root.focusedMonitor?.lastIpcObject?.specialWorkspace?.name;

            if (specialName && specialName.startsWith("special:")) {
                root.lastSpecialWorkspace = specialName;
            }
        }

        target: root.isNiri ? null : root.focusedMonitor
    }

    FileView {
        id: kbLayoutFile

        path: Quickshell.env("CAELESTIA_XKB_RULES_PATH") || "/usr/share/X11/xkb/rules/base.lst"
        onLoaded: {
            const layoutMatch = text().match(/! layout\n([\s\S]*?)\n\n/);
            if (layoutMatch) {
                const lines = layoutMatch[1].split("\n");
                for (const line of lines) {
                    if (!line.trim() || line.trim().startsWith("!"))
                        continue;

                    const match = line.match(/^\s*([a-z]{2,})\s+([a-zA-Z() ]+)$/);
                    if (match)
                        root.kbMap.set(match[2], match[1]);
                }
            }

            const variantMatch = text().match(/! variant\n([\s\S]*?)\n\n/);
            if (variantMatch) {
                const lines = variantMatch[1].split("\n");
                for (const line of lines) {
                    if (!line.trim() || line.trim().startsWith("!"))
                        continue;

                    const match = line.match(/^\s*([a-zA-Z0-9_-]+)\s+([a-z]{2,}): (.+)$/);
                    if (match)
                        root.kbMap.set(match[3], match[2]);
                }
            }
        }
    }

    IpcHandler {
        function refreshDevices(): void {
            if (!root.isNiri) extras.refreshDevices();
        }

        function cycleSpecialWorkspace(direction: string): void {
            root.cycleSpecialWorkspace(direction);
        }

        function listSpecialWorkspaces(): string {
            if (root.isNiri) return "";
            return root.workspaces.values.filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0).map(w => w.name).join("\n");
        }

        target: "hypr"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "refreshDevices"
        description: "Reload devices"
        onPressed: if (!root.isNiri) extras.refreshDevices()
        onReleased: if (!root.isNiri) extras.refreshDevices()
    }

    HyprExtras {
        id: extras

        usingLua: Hyprland.usingLua
    }
}
