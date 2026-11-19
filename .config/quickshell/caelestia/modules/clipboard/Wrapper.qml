pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.clipboard

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels

    readonly property bool shouldBeActive: screenState.clipboard && Config.launcher.enabled

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;
        if (screenState.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: 480
    implicitWidth: 630
    width: 630
    height: 480
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainer
        border.color: Colours.palette.m3outlineVariant
        border.width: Config.border.thickness

        ClipboardContent {
            anchors.fill: parent
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}
