pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: search.height + listWrapper.height + padding + search.anchors.bottomMargin

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    SearchBar {
        id: search

        objectName: "customLauncherSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: {
            const curList = list.currentList;
            if (curList && curList.navStack && curList.navStack.length > 0) {
                const trail = curList.navStack.map(i => i.name).join(" > ");
                return `${trail} > Search...`;
            }
            return "Search options, apps, and tools...";
        }

        function activateCurrent(): void {
            const curList = list.currentList;
            const currentItem = curList?.currentItem;
            if (currentItem && currentItem.activate) {
                currentItem.activate();
            }
        }

        onAccepted: activateCurrent()

        Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

        // Right arrow drills down into child action
        Keys.onRightPressed: activateCurrent()

        // Left arrow goes back
        Keys.onLeftPressed: {
            if (search.cursorPosition === 0) {
                const curList = list.currentList;
                if (curList && curList.goBack && curList.goBack()) {
                    return;
                }
            }
        }

        // Smart Escape: Back up one level, or close drawer if at root
        Keys.onEscapePressed: {
            const curList = list.currentList;
            if (curList && curList.goBack && curList.goBack()) {
                return;
            }
            root.screenState.customlauncher = false;
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                activateCurrent();
                event.accepted = true;
                return;
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onCustomlauncherChanged(): void {
                if (root.screenState.customlauncher) {
                    search.forceActiveFocus();
                } else {
                    search.text = "";
                }
            }

            function onSessionChanged(): void {
                if (!root.screenState.session && root.screenState.customlauncher)
                    search.forceActiveFocus();
            }

            target: root.screenState
        }
    }
}
