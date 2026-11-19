pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property ScreenState screenState
    property var list

    readonly property bool isItemImage: Boolean(modelData && modelData.isImage)
    readonly property string itemImagePath: (modelData && modelData.imagePath) ? modelData.imagePath : ""
    readonly property string itemText: (modelData && modelData.text) ? modelData.text : ""
    readonly property string itemDims: (modelData && modelData.dims) ? modelData.dims : ""
    readonly property string itemId: (modelData && modelData.id) ? String(modelData.id) : ""

    implicitHeight: isItemImage ? 90 : 52

    anchors.left: parent?.left
    anchors.right: parent?.right

    function activate(): void {
        if (root.itemId.length > 0)
            ClipboardService.paste(root.itemId);
        if (root.screenState.clipboard)
            root.screenState.clipboard = false;
        if (root.screenState.launcher)
            root.screenState.launcher = false;
    }

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.activate()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Left Icon / Image preview with M3 rounded thumbnail card
        StyledRect {
            Layout.preferredWidth: root.isItemImage ? 72 : 36
            Layout.preferredHeight: root.isItemImage ? 72 : 36
            Layout.alignment: Qt.AlignVCenter
            radius: root.isItemImage ? Tokens.rounding.medium : Tokens.rounding.small
            color: root.isItemImage ? Colours.palette.m3surfaceContainerLowest : Qt.alpha(Colours.palette.m3primary, 0.12)
            clip: true

            Image {
                visible: root.isItemImage && root.itemImagePath.length > 0
                anchors.fill: parent
                anchors.margins: 4
                fillMode: Image.PreserveAspectFit
                source: root.itemImagePath
                asynchronous: true
                smooth: true
                cache: true
            }

            MaterialIcon {
                visible: !root.isItemImage || root.itemImagePath.length === 0
                anchors.centerIn: parent
                text: root.isItemImage ? "image" : "content_paste"
                fontStyle: root.isItemImage ? Tokens.font.icon.large : Tokens.font.icon.medium
                color: Colours.palette.m3primary
            }
        }

        // Details
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            StyledText {
                Layout.fillWidth: true
                text: root.isItemImage ? `Image (${root.itemDims || "Preview"})` : root.itemText
                font: Tokens.font.body.medium
                elide: Text.ElideRight
                maximumLineCount: root.isItemImage ? 1 : 2
                wrapMode: Text.WrapAnywhere
            }

            StyledText {
                visible: root.isItemImage
                Layout.fillWidth: true
                text: root.itemText
                font: Tokens.font.label.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }

        // Delete button
        StyledRect {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: Tokens.rounding.full
            color: deleteHover.containsMouse ? Colours.palette.m3errorContainer : "transparent"

            StateLayer {
                id: deleteHover
                radius: Tokens.rounding.full
                onClicked: {
                    if (root.itemId.length > 0)
                        ClipboardService.remove(root.itemId);
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "close"
                fontStyle: Tokens.font.icon.medium
                color: deleteHover.containsMouse ? Colours.palette.m3error : Colours.palette.m3outline
            }
        }
    }
}
