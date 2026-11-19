pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Io
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property var quickToggles: {
        const seenIds = new Set();

        return Config.utilities.quickToggles.values.filter(item => {
            if (!item.enabled)
                return false;

            if (seenIds.has(item.id)) {
                return false;
            }

            if (item.id === "vpn") {
                return GlobalConfig.utilities.vpn.selectedProvider.length > 0;
            }

            seenIds.add(item.id);
            return true;
        });
    }
    readonly property int splitIndex: Math.ceil(quickToggles.length / 2)
    readonly property bool needExtraRow: quickToggles.length > 6

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    Process {
        id: displayProc
        command: ["/home/darshan/.local/bin/display-launcher"]
        running: false
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledText {
            text: Tr.tr("Quick toggles")
            font: Tokens.font.body.medium
        }

        QuickToggleRow {
            model: root.needExtraRow ? root.quickToggles.slice(0, root.splitIndex) : root.quickToggles
        }

        QuickToggleRow {
            visible: root.needExtraRow
            model: root.needExtraRow ? root.quickToggles.slice(root.splitIndex) : []
        }
    }

    component QuickToggleRow: ButtonRow {
        property alias model: repeater.model

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            id: repeater

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        tooltipText: Tr.tr("Wi-Fi")
                        checked: Nmcli.wifiEnabled
                        onClicked: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        tooltipText: Tr.tr("Bluetooth")
                        checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
                        onClicked: {
                            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        tooltipText: Tr.tr("Microphone")
                        checked: !Audio.sourceMuted
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "voxtype"
                    delegate: Toggle {
                        icon: "record_voice_over"
                        tooltipText: Tr.tr("Voice Dictation (VoxType)")
                        tooltipSubtext: VoxTypeService.recording ? Tr.tr("Recording...") : Tr.tr("Idle")
                        checked: VoxTypeService.recording
                        onClicked: VoxTypeService.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        tooltipText: Tr.tr("Settings")
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.screenState.utilities = false;
                            WindowFactory.create();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "gameMode"
                    delegate: Toggle {
                        icon: "gamepad"
                        tooltipText: Tr.tr("Game Mode")
                        checked: GameMode.enabled
                        onClicked: GameMode.enabled = !GameMode.enabled
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        tooltipText: Tr.tr("Do Not Disturb")
                        checked: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        tooltipText: Tr.tr("VPN")
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting && !VPN.disconnecting
                        isToggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: VPN.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "caffeine"
                    delegate: Toggle {
                        icon: "coffee"
                        tooltipText: Tr.tr("Caffeine")
                        tooltipSubtext: IdleInhibitor.enabled
                            ? (IdleInhibitor.enabledSince
                                ? Tr.tr("Active since %1").arg(Qt.formatTime(IdleInhibitor.enabledSince, Units.twelveHourClock ? "hh:mm a" : "hh:mm"))
                                : Tr.tr("Preventing sleep mode"))
                            : Tr.tr("Normal power management")
                        checked: IdleInhibitor.enabled
                        onClicked: IdleInhibitor.enabled = !IdleInhibitor.enabled
                    }
                }
                DelegateChoice {
                    roleValue: "nightlight"
                    delegate: Toggle {
                        icon: NightLight.active ? "nights_stay" : "wb_sunny"
                        tooltipText: Tr.tr("Night Light")
                        checked: NightLight.active
                        onClicked: NightLight.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "display"
                    delegate: Toggle {
                        icon: "display_settings"
                        tooltipText: Tr.tr("Display Settings")
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.screenState.utilities = false;
                            displayProc.running = true;
                        }
                    }
                }
            }
        }
    }

    component Toggle: IconButton {
        id: toggleBtn
        property string tooltipText: ""
        property string tooltipSubtext: ""

        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        fillWidth: true
        isToggle: true
        isRound: true
        shapeMorph: true

        ToolTip {
            visible: toggleBtn.tooltipText.length > 0 && toggleBtn.hovered
            delay: 200
            text: toggleBtn.tooltipText

            contentItem: ColumnLayout {
                spacing: 2

                StyledText {
                    text: toggleBtn.tooltipText
                    color: Colours.palette.m3inverseOnSurface
                    font: Tokens.font.label.medium
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    visible: toggleBtn.tooltipSubtext.length > 0
                    text: toggleBtn.tooltipSubtext
                    color: Qt.alpha(Colours.palette.m3inverseOnSurface, 0.75)
                    font: Tokens.font.label.small
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            background: StyledRect {
                radius: Tokens.rounding.small
                color: Colours.palette.m3inverseSurface
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.4)

                Elevation {
                    anchors.fill: parent
                    radius: parent.radius
                    z: -1
                    level: 2
                }
            }
        }
    }
}
