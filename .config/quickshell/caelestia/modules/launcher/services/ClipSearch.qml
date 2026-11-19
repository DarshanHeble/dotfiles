pragma Singleton

import ".."
import QtQuick
import Caelestia.Config
import qs.services
import qs.utils

Searcher {
    id: root

    function transformSearch(search: string): string {
        const prefix = GlobalConfig.launcher.actionPrefix;
        if (search.startsWith(`${prefix}clip `))
            return search.slice(`${prefix}clip `.length).trim();
        return "";
    }

    list: ClipboardService.clips || []

    function search(text: string): var {
        const q = transformSearch(text).toLowerCase();
        const all = ClipboardService.clips || [];
        if (!q) return all;
        return all.filter(c => (c.text || "").toLowerCase().includes(q));
    }
}
