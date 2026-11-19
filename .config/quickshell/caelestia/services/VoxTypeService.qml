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

    property bool recording: false

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: checkStatus()
    }

    Process {
        id: statusProc
        command: ["bash", "-c", "pgrep -x voxtype >/dev/null 2>&1 && cat /run/user/$(id -u)/voxtype/state 2>/dev/null || echo idle"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!toggleProc.running) {
                    root.recording = (text.trim() === "recording");
                }
            }
        }
    }

    function checkStatus(): void {
        if (!statusProc.running && !toggleProc.running)
            statusProc.running = true;
    }

    function toggle(): void {
        root.recording = !root.recording;
        toggleProc.running = true;
    }

    Process {
        id: toggleProc
        command: ["/home/darshan/.local/bin/voxtype-toggle"]
        running: false
        onExited: {
            checkStatus();
        }
    }
}
