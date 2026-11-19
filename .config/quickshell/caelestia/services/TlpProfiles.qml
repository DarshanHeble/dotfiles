pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int profile: 1
    readonly property int degradationReason: 0

    Process {
        id: getProc
        command: ["/home/darshan/.local/bin/tlp-control", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const res = text.trim();
                if (res === "power-saver") {
                    root.profile = 2;
                } else if (res === "performance") {
                    root.profile = 0;
                } else {
                    root.profile = 1;
                }
            }
        }
    }

    Process {
        id: setProc
        running: false
        onExited: {
            root.refresh();
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh(): void {
        if (!getProc.running) {
            getProc.running = true;
        }
    }

    function setProfile(p: int): void {
        root.profile = p;
        let mode = "balanced";
        if (p === 2) {
            mode = "power-saver";
        } else if (p === 0) {
            mode = "performance";
        }
        setProc.command = ["/home/darshan/.local/bin/tlp-control", "set", mode];
        setProc.running = true;
    }
}
