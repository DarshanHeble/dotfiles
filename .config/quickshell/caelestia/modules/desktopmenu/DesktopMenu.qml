pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import qs.modules.nexus

Scope {
    id: root

    property bool isOpen: false
    property real menuX: 100
    property real menuY: 100
    property int hoveredIdx: -1
    property ShellScreen activeScreen: Screens.screens[0]

    function openAt(x: real, y: real, screen: ShellScreen): void {
        hoveredIdx = -1;
        activeScreen = screen ?? ShellState.forActive()?.modelData ?? Screens.screens[0];
        const sw = activeScreen ? activeScreen.width : 1920;
        const sh = activeScreen ? activeScreen.height : 1080;
        const menuW = 270;
        const menuH = 440;

        menuX = Math.max(16, Math.min(x, sw - menuW - 16));
        menuY = Math.max(16, Math.min(y, sh - menuH - 16));
        isOpen = true;
    }

    function close(): void {
        isOpen = false;
        hoveredIdx = -1;
    }

    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const pos = JSON.parse(text.trim());
                        root.openAt(pos.x, pos.y, ShellState.forActive()?.modelData ?? Screens.screens[0]);
                    } catch (e) {
                        root.openAt(100, 100, Screens.screens[0]);
                    }
                }
            }
        }
    }

    // Expose IPC command
    IpcHandler {
        function open(): void {
            cursorProc.running = true;
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            if (root.isOpen)
                root.close();
            else
                open();
        }

        target: "desktopmenu"
    }

    LazyLoader {
        id: loader

        active: root.isOpen

        StyledWindow {
            id: win

            screen: root.activeScreen
            name: "desktop-context-menu"

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"
            surfaceFormat.opaque: false

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Shortcut {
                sequence: "Escape"
                enabled: root.isOpen
                onActivated: root.close()
            }

            // Click outside dismiss area
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onPressed: root.close()
                onWheel: e => e.accepted = true
            }

            // M3 Expressive Menu Card
            Elevation {
                id: menuContainer

                x: root.menuX
                y: root.menuY
                width: 270
                implicitHeight: contentCol.implicitHeight + Tokens.padding.medium * 2

                radius: Tokens.rounding.extraLarge
                level: 3

                transformOrigin: Item.TopLeft

                // Absorb click inside menu
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onWheel: e => e.accepted = true
                }

                StyledRect {
                    anchors.fill: parent
                    radius: menuContainer.radius
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.45)

                    ColumnLayout {
                        id: contentCol

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: 3

                        // Header / Expressive Title badge
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 34

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.medium
                                anchors.rightMargin: Tokens.padding.medium
                                spacing: Tokens.padding.small

                                MaterialIcon {
                                    text: "auto_awesome"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.small
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: "DESKTOP"
                                    color: Colours.palette.m3primary
                                    font: Tokens.font.label.small
                                    opacity: 0.95
                                }

                                StyledText {
                                    text: "M3 Expressive"
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                    opacity: 0.6
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: Tokens.padding.small
                            Layout.rightMargin: Tokens.padding.small
                            height: 1
                            color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
                        }

                        // Menu Item 0: Terminal
                        MenuItemButton {
                            itemIndex: 0
                            icon: "terminal"
                            title: "Terminal"
                            shortcutHint: "Super + Ret"
                            onTriggered: {
                                root.close();
                                Quickshell.execDetached(["foot"]);
                            }
                        }

                        // Menu Item 1: File Manager
                        MenuItemButton {
                            itemIndex: 1
                            icon: "folder_open"
                            title: "File Manager"
                            shortcutHint: "Super + E"
                            onTriggered: {
                                root.close();
                                Quickshell.execDetached(["nautilus"]);
                            }
                        }

                        // Menu Item 2: Browser
                        MenuItemButton {
                            itemIndex: 2
                            icon: "language"
                            title: "Browser"
                            shortcutHint: "Super + Shift + B"
                            onTriggered: {
                                root.close();
                                Quickshell.execDetached(["chromium"]);
                            }
                        }

                        // Menu Item 3: Launcher
                        MenuItemButton {
                            itemIndex: 3
                            icon: "apps"
                            title: "Applications"
                            shortcutHint: "Super + Space"
                            onTriggered: {
                                root.close();
                                const s = ShellState.forScreen(win.screen);
                                if (s) s.launcher = true;
                            }
                        }

                        // Separator
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: Tokens.padding.small
                            Layout.rightMargin: Tokens.padding.small
                            height: 1
                            color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
                        }

                        // Menu Item 4: Wallpaper Selector
                        MenuItemButton {
                            itemIndex: 4
                            icon: "wallpaper"
                            title: "Change Wallpaper"
                            onTriggered: {
                                root.close();
                                WindowFactory.create();
                            }
                        }

                        // Menu Item 5: Dashboard & Controls
                        MenuItemButton {
                            itemIndex: 5
                            icon: "dashboard"
                            title: "Dashboard"
                            shortcutHint: "Alt + Space"
                            onTriggered: {
                                root.close();
                                const s = ShellState.forScreen(win.screen);
                                if (s) s.dashboard = true;
                            }
                        }

                        // Menu Item 6: Settings / Nexus
                        MenuItemButton {
                            itemIndex: 6
                            icon: "settings"
                            title: "Caelestia Settings"
                            onTriggered: {
                                root.close();
                                WindowFactory.create();
                            }
                        }

                        // Separator
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: Tokens.padding.small
                            Layout.rightMargin: Tokens.padding.small
                            height: 1
                            color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
                        }

                        // Menu Item 7: Lock / Session
                        MenuItemButton {
                            itemIndex: 7
                            icon: "power_settings_new"
                            title: "Power & Session"
                            shortcutHint: "Super + Esc"
                            isDestructive: true
                            onTriggered: {
                                root.close();
                                const s = ShellState.forScreen(win.screen);
                                if (s) s.session = true;
                            }
                        }
                    }
                }
            }
        }
    }

    // Exact initial clean styling with single active hover tracking
    component MenuItemButton: StyledRect {
        id: btn

        required property int itemIndex
        property string icon
        property string title
        property string shortcutHint
        property bool isDestructive: false

        signal triggered()

        readonly property bool isHovered: root.hoveredIdx === btn.itemIndex

        Layout.fillWidth: true
        implicitHeight: 40
        radius: Tokens.rounding.medium

        color: {
            if (btn.isHovered) {
                if (btn.isDestructive)
                    return Qt.alpha(Colours.palette.m3errorContainer, 0.7);
                return Qt.alpha(Colours.palette.m3secondaryContainer, 0.8);
            }
            return "transparent";
        }

        scale: mouse.pressed ? 0.97 : (btn.isHovered ? 1.02 : 1.0)

        Behavior on scale {
            Anim { duration: 150; easing: Tokens.anim.standard }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.padding.medium

            MaterialIcon {
                text: btn.icon
                fontStyle: Tokens.font.icon.small
                color: {
                    if (btn.isDestructive && btn.isHovered)
                        return Colours.palette.m3onErrorContainer;
                    if (btn.isHovered)
                        return Colours.palette.m3onSecondaryContainer;
                    return Colours.palette.m3onSurfaceVariant;
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: btn.title
                font: Tokens.font.body.medium
                color: {
                    if (btn.isDestructive && btn.isHovered)
                        return Colours.palette.m3onErrorContainer;
                    if (btn.isHovered)
                        return Colours.palette.m3onSecondaryContainer;
                    return Colours.palette.m3onSurface;
                }
            }

            StyledText {
                visible: btn.shortcutHint.length > 0
                text: btn.shortcutHint
                font: Tokens.font.label.small
                opacity: btn.isHovered ? 0.9 : 0.5
                color: {
                    if (btn.isDestructive && btn.isHovered)
                        return Colours.palette.m3onErrorContainer;
                    if (btn.isHovered)
                        return Colours.palette.m3onSecondaryContainer;
                    return Colours.palette.m3outline;
                }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton

            onEntered: root.hoveredIdx = btn.itemIndex
            onExited: {
                if (root.hoveredIdx === btn.itemIndex)
                    root.hoveredIdx = -1;
            }
            onClicked: btn.triggered()
        }
    }
}
