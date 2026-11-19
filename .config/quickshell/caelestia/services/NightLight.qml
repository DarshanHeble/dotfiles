pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services

Singleton {
    id: root

    property bool active: false
    property int temperature: 3500

    Timer {
        id: pollTimer
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: checkStatus()
    }

    Process {
        id: statusProc
        command: ["/home/darshan/.local/bin/nightlight-control", "get-status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!toggleProc.running) {
                    root.active = (text.trim() === "on");
                }
            }
        }
    }

    Process {
        id: tempProc
        command: ["/home/darshan/.local/bin/nightlight-control", "get-temp"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim());
                if (!isNaN(val) && val >= 1000 && val <= 6500) {
                    root.temperature = val;
                }
            }
        }
    }

    function checkStatus(): void {
        if (!statusProc.running && !toggleProc.running)
            statusProc.running = true;
        if (!tempProc.running)
            tempProc.running = true;
    }

    function toggle(): void {
        root.active = !root.active;
        toggleProc.command = ["/home/darshan/.local/bin/nightlight-control", root.active ? "on" : "off"];
        toggleProc.running = true;
    }

    function setTemperature(temp: int): void {
        root.temperature = temp;
        setTempProc.command = ["/home/darshan/.local/bin/nightlight-control", "set-temp", String(temp)];
        setTempProc.running = true;
    }

    Process {
        id: toggleProc
        running: false
        onExited: {
            checkStatus();
        }
    }

    Process {
        id: setTempProc
        running: false
    }
}
