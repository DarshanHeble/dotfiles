pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.services

Singleton {
    id: root

    property var clips: []
    property bool loading: false

    function refresh(): void {
        console.log("ClipboardService: refresh() called");
        fetchProc.running = true;
    }

    function paste(id: string): void {
        Quickshell.execDetached(["/home/darshan/.local/bin/caelestia-clip", "paste", id]);
    }

    function remove(id: string): void {
        Quickshell.execDetached(["/home/darshan/.local/bin/caelestia-clip", "delete", id]);
        refresh();
    }

    Process {
        id: fetchProc

        command: ["/home/darshan/.local/bin/caelestia-clip", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("ClipboardService: fetchProc onStreamFinished, length:", text.length);
                try {
                    root.clips = JSON.parse(text.trim());
                    console.log("ClipboardService: parsed clips count:", root.clips.length);
                } catch (e) {
                    console.error("Failed to parse clips JSON:", e);
                }
            }
        }
    }

    Component.onCompleted: {
        refresh();
    }
}
