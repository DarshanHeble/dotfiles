#!/usr/bin/env python3
import os
import glob
import json

def get_apps():
    dirs = [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/local/share/applications",
        "/usr/share/applications"
    ]
    seen = set()
    apps = []

    for d in dirs:
        if not os.path.exists(d):
            continue
        for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
            base = os.path.basename(f)
            if base in seen:
                continue
            seen.add(base)
            name = None
            exec_cmd = None
            icon = "apps"
            no_display = False
            try:
                with open(f, "r", encoding="utf-8", errors="ignore") as fp:
                    for line in fp:
                        line = line.strip()
                        if line.startswith("NoDisplay=true"):
                            no_display = True
                            break
                        if line.startswith("Name=") and not name:
                            name = line.split("=", 1)[1].strip()
                        elif line.startswith("Exec=") and not exec_cmd:
                            raw = line.split("=", 1)[1].strip()
                            # remove %u, %F etc
                            exec_cmd = " ".join([p for p in raw.split() if not p.startswith("%")])
                        elif line.startswith("Icon=") and icon == "apps":
                            icon = line.split("=", 1)[1].strip()
            except Exception:
                continue

            if no_display or not name or not exec_cmd:
                continue

            apps.append({
                "name": name,
                "exec": exec_cmd,
                "icon": icon,
                "desktop": base
            })

    apps.sort(key=lambda x: x["name"].lower())
    return apps

if __name__ == "__main__":
    print(json.dumps(get_apps()))
