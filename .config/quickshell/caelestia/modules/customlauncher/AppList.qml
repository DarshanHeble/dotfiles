pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import "items"

StyledListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    property string displayText
    property var navStack: [] // Navigation stack: array of { title: string, items: [...] }
    property var installedSet: ({})

    // Scan installed binaries asynchronously via non-blocking process
    Process {
        id: pkgCheckProc
        command: ["sh", "-c", "which google-chrome google-chrome-stable zen-browser brave brave-browser firefox chromium kitty alacritty foot wezterm ghostty 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                if (text && text.trim()) {
                    const lines = text.trim().split("\n");
                    for (const line of lines) {
                        const parts = line.trim().split("/");
                        const bin = parts[parts.length - 1];
                        if (bin) map[bin] = true;
                    }
                }
                root.installedSet = map;
            }
        }
    }

    function checkInstalled(): void {
        pkgCheckProc.running = true;
    }

    function isInstalled(bins: list<string>): bool {
        for (const b of bins) {
            if (root.installedSet[b])
                return true;
        }
        return false;
    }

    // Launch installation using Caelestia Presentation Terminal
    function installPkg(name: string, pkgName: string): void {
        root.screenState.customlauncher = false;
        Quickshell.execDetached([
            "/home/darshan/.local/bin/caelestia-presentation-terminal",
            `Installing ${name}`,
            `paru -S --needed ${pkgName}`
        ]);
        // Refresh installed check after triggering
        root.checkInstalled();
    }

    // Browsers database
    readonly property var browsersDb: [
        {
            name: "Google Chrome",
            desc: "Fast, secure browser by Google",
            icon: "public",
            pkg: "google-chrome",
            bins: ["google-chrome", "google-chrome-stable"]
        },
        {
            name: "Zen Browser",
            desc: "Beautiful, privacy-focused Firefox-based browser",
            icon: "language",
            pkg: "zen-browser-bin",
            bins: ["zen-browser"]
        },
        {
            name: "Brave Browser",
            desc: "Privacy-focused browser with ad-blocking",
            icon: "shield",
            pkg: "brave-bin",
            bins: ["brave", "brave-browser"]
        },
        {
            name: "Firefox Developer Edition",
            desc: "The browser made for developers",
            icon: "web",
            pkg: "firefox-developer-edition",
            bins: ["firefox-developer-edition"]
        },
        {
            name: "Microsoft Edge",
            desc: "Chromium-based browser by Microsoft",
            icon: "public",
            pkg: "microsoft-edge-stable-bin",
            bins: ["microsoft-edge-stable", "microsoft-edge"]
        },
        {
            name: "Vivaldi",
            desc: "Feature-rich, customizable browser",
            icon: "language",
            pkg: "vivaldi",
            bins: ["vivaldi"]
        }
    ]

    // Terminals database
    readonly property var terminalsDb: [
        {
            name: "WezTerm",
            desc: "GPU-accelerated cross-platform terminal emulator",
            icon: "terminal",
            pkg: "wezterm",
            bins: ["wezterm"]
        },
        {
            name: "Kitty",
            desc: "Fast, feature-rich, GPU-based terminal emulator",
            icon: "terminal",
            pkg: "kitty",
            bins: ["kitty"]
        },
        {
            name: "Alacritty",
            desc: "A fast, cross-platform, OpenGL terminal emulator",
            icon: "terminal",
            pkg: "alacritty",
            bins: ["alacritty"]
        },
        {
            name: "Foot",
            desc: "A fast, lightweight Wayland terminal emulator",
            icon: "terminal",
            pkg: "foot",
            bins: ["foot"]
        },
        {
            name: "Ghostty",
            desc: "Fast, feature-rich, native GPU-accelerated terminal",
            icon: "terminal",
            pkg: "ghostty",
            bins: ["ghostty"]
        }
    ]

    function getUninstalledBrowsers(): var {
        const list = [];
        for (const item of root.browsersDb) {
            if (!root.isInstalled(item.bins)) {
                list.push({
                    name: item.name,
                    desc: item.desc,
                    icon: item.icon,
                    hasSubactions: false,
                    action: () => root.installPkg(item.name, item.pkg)
                });
            }
        }
        return list;
    }

    function getUninstalledTerminals(): var {
        const list = [];
        for (const item of root.terminalsDb) {
            if (!root.isInstalled(item.bins)) {
                list.push({
                    name: item.name,
                    desc: item.desc,
                    icon: item.icon,
                    hasSubactions: false,
                    action: () => root.installPkg(item.name, item.pkg)
                });
            }
        }
        return list;
    }

    // Dynamic Tree Hierarchy
    readonly property var rootEntries: [
        {
            name: "Install",
            desc: "Install web browsers, terminals, and packages",
            icon: "download",
            hasSubactions: true,
            children: function() {
                return [
                    {
                        name: "Browser",
                        desc: "Install web browsers (uninstalled only)",
                        icon: "public",
                        hasSubactions: true,
                        children: () => root.getUninstalledBrowsers()
                    },
                    {
                        name: "Terminal",
                        desc: "Install terminal emulators (uninstalled only)",
                        icon: "terminal",
                        hasSubactions: true,
                        children: () => root.getUninstalledTerminals()
                    }
                ];
            }
        },
        {
            name: "Update",
            desc: "Update system packages, firmware, and software",
            icon: "system_update_alt",
            hasSubactions: false,
            action: function() {
                root.screenState.customlauncher = false;
                Quickshell.execDetached([
                    "/home/darshan/.local/bin/caelestia-presentation-terminal",
                    "System & Package Update",
                    "paru -Syu"
                ]);
            }
        },
        {
            name: "Toggle",
            desc: "Toggle desktop settings, services, and system states",
            icon: "toggle_on",
            hasSubactions: false,
            action: function() {
                // Placeholder for Step 3
            }
        },
        {
            name: "Style",
            desc: "Customise desktop theme, wallpapers, and appearance",
            icon: "palette",
            hasSubactions: false,
            action: function() {
                // Placeholder for Step 3
            }
        }
    ]

    // Current items based on navigation stack
    function currentLevelItems(): var {
        if (root.navStack.length === 0)
            return root.rootEntries;

        const current = root.navStack[root.navStack.length - 1];
        if (typeof current.children === "function")
            return current.children();
        return current.children || [];
    }

    // Drill down into child subaction
    function drillDown(item: var): void {
        const stackCopy = root.navStack.slice();
        stackCopy.push(item);
        root.navStack = stackCopy;
        root.search.text = "";
        root.displayText = "";
        root.currentIndex = 0;
    }

    // Step back one level
    function goBack(): bool {
        if (root.search.text.length > 0) {
            root.search.text = "";
            root.displayText = "";
            return true;
        }

        if (root.navStack.length > 0) {
            const stackCopy = root.navStack.slice();
            stackCopy.pop();
            root.navStack = stackCopy;
            root.search.text = "";
            root.displayText = "";
            root.currentIndex = 0;
            return true;
        }

        return false;
    }

    // Reset navigation stack to root
    function resetNav(): void {
        root.navStack = [];
        root.search.text = "";
        root.displayText = "";
        root.currentIndex = 0;
    }

    function resultsForText(text: string): var {
        let items = root.currentLevelItems();
        const q = (text || "").toLowerCase().trim();

        if (q.length > 0) {
            items = items.filter(item => {
                const nameMatch = item.name && item.name.toLowerCase().includes(q);
                const descMatch = item.desc && item.desc.toLowerCase().includes(q);
                return nameMatch || descMatch;
            });
        }

        return items;
    }

    model: ScriptModel {
        values: root.resultsForText(root.displayText)
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, Math.max(1, count)) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    delegate: CustomHubItem {
        screenState: root.screenState
        list: root
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    Component.onCompleted: {
        displayText = search.text;
        checkInstalled();
    }

    Connections {
        function onTextChanged() {
            root.displayText = root.search.text;
        }

        target: root.search
    }

    Connections {
        function onCustomlauncherChanged() {
            if (root.screenState.customlauncher) {
                root.checkInstalled();
                root.resetNav();
            }
        }

        target: root.screenState
    }
}
