pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.items

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge

    implicitWidth: 630
    implicitHeight: 480

    onVisibleChanged: {
        if (visible) {
            ClipboardService.refresh();
            search.text = "";
            search.forceActiveFocus();
        }
    }

    Item {
        id: listWrapper

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: search.top
        anchors.top: parent.top
        anchors.margins: root.padding
        clip: true

        ListView {
            id: listView

            anchors.fill: parent
            spacing: Tokens.spacing.small
            clip: true

            model: ScriptModel {
                values: {
                    const q = search.text.toLowerCase().trim();
                    const all = ClipboardService.clips || [];
                    if (!q) return all;
                    return all.filter(item => (item.text || "").toLowerCase().includes(q));
                }
            }

            delegate: ClipItem {
                screenState: root.screenState
                list: listView
            }

            StyledText {
                visible: listView.count === 0
                anchors.centerIn: parent
                text: "No clipboard history"
                font: Tokens.font.body.medium
                color: Colours.palette.m3outline
            }
        }
    }

    SearchBar {
        id: search

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: "Search clipboard history..."

        onAccepted: {
            if (listView.count > 0 && listView.currentItem) {
                listView.currentItem.activate();
            }
        }

        Keys.onEscapePressed: {
            root.screenState.clipboard = false;
        }

        Keys.onUpPressed: listView.decrementCurrentIndex()
        Keys.onDownPressed: listView.incrementCurrentIndex()
    }
}
