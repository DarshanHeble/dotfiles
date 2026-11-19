pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    readonly property real nonAnimHeight: (layout.implicitHeight + Tokens.padding.large * 2) * (NightLight.active ? 1 : 0)

    Layout.fillWidth: true
    Layout.preferredHeight: nonAnimHeight
    opacity: NightLight.active ? 1 : 0
    visible: Layout.preferredHeight > 0 || opacity > 0

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true

            MaterialIcon {
                text: "nights_stay"
                fontStyle: Tokens.font.icon.small
                color: Colours.palette.m3primary
            }

            StyledText {
                text: Tr.tr("Night Light Warmth")
                font: Tokens.font.label.medium
                color: Colours.palette.m3onSurface
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: NightLight.temperature + "K"
                font: Tokens.font.label.medium
                color: Colours.palette.m3primary
            }
        }

        StyledSlider {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 2
            radius: Tokens.rounding.small

            // Map 2000K (warmest, slider=1) to 6000K (coolest, slider=0)
            value: Math.max(0, Math.min(1, (6000 - NightLight.temperature) / 4000))

            onInteraction: (v) => {
                const targetK = Math.round(6000 - v * 4000);
                NightLight.setTemperature(targetK);
            }
        }
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.SlowEffects
        }
    }
}
