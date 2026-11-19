pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property ScreenState screenState
    property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    readonly property bool hasChildren: Boolean(root.modelData && (root.modelData.hasSubactions === true || root.modelData.children !== undefined))

    function activate(): void {
        if (root.hasChildren) {
            if (root.list && root.list.drillDown) {
                root.list.drillDown(root.modelData);
            }
        } else if (root.modelData && root.modelData.action) {
            root.modelData.action();
            root.screenState.customlauncher = false;
        }
    }

    StateLayer {
        id: stateLayer
        radius: Tokens.rounding.large
        onClicked: root.activate()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small
        spacing: Tokens.spacing.medium

        // Left Icon
        StyledRect {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            radius: Tokens.rounding.medium
            color: Qt.alpha(Colours.palette.m3primary, 0.12)

            MaterialIcon {
                anchors.centerIn: parent
                text: root.modelData?.icon ?? "star"
                fontStyle: Tokens.font.icon.medium
                color: Colours.palette.m3primary
            }
        }

        // Details
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                text: root.modelData?.desc ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }

        // Right Arrow for items with subactions
        Item {
            visible: root.hasChildren
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter

            MaterialIcon {
                id: arrowIcon
                anchors.centerIn: parent
                text: "chevron_right"
                fontStyle: Tokens.font.icon.large
                color: stateLayer.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                anchors.horizontalCenterOffset: stateLayer.containsMouse ? 2 : 0

                Behavior on anchors.horizontalCenterOffset {
                    Anim { duration: 150 }
                }
                Behavior on color {
                    CAnim { duration: 150 }
                }
            }
        }
    }
}
