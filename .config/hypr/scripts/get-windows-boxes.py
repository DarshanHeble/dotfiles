import json
import subprocess
import sys

def get_boxes():
    boxes = []
    # Try hyprland first
    try:
        clients = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"], stderr=subprocess.DEVNULL))
        monitors = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"], stderr=subprocess.DEVNULL))
        active_ws = {m.get("activeWorkspace", {}).get("id") for m in monitors}
        for c in clients:
            ws_id = c.get("workspace", {}).get("id")
            if ws_id in active_ws and not c.get("hidden", False) and c.get("mapped", True):
                x, y = c["at"]
                w, h = c["size"]
                if w > 0 and h > 0:
                    boxes.append(f"{x},{y} {w}x{h}")
    except Exception:
        # Fallback to niri if running under niri
        try:
            windows = json.loads(subprocess.check_output(["niri", "msg", "-j", "windows"], stderr=subprocess.DEVNULL))
            monitors_raw = json.loads(subprocess.check_output(["niri", "msg", "-j", "outputs"], stderr=subprocess.DEVNULL))
            monitors = []
            for name, mdata in monitors_raw.items():
                modes = mdata.get("modes", [])
                curr_idx = mdata.get("current_mode", 0)
                curr_mode = modes[curr_idx] if curr_idx < len(modes) else {}
                scale = mdata.get("scale", 1.0)
                logical = mdata.get("logical", {})
                w = logical.get("width") or int(curr_mode.get("width", 1920) / scale)
                h = logical.get("height") or int(curr_mode.get("height", 1080) / scale)
                x = logical.get("x", 0)
                y = logical.get("y", 0)
                monitors.append({"x": x, "y": y, "width": w, "height": h, "focused": mdata.get("is_focused", False)})

            for w in windows:
                if w.get("is_focused") or w.get("is_floating") or not w.get("is_urgent"):
                    layout = w.get("layout", {})
                    pos = layout.get("position", {})
                    size = layout.get("size", {})
                    if size.get("width") and size.get("height"):
                        boxes.append(f"{pos.get('x', 0)},{pos.get('y', 0)} {size['width']}x{size['height']}")
        except Exception:
            monitors = []

    # Check open Caelestia shell panels/drawers so smart snapping also snaps to them
    primary_mon = next((m for m in monitors if m.get("focused")), monitors[0] if monitors else {})
    mon_w = primary_mon.get("width", 1920)
    mon_h = primary_mon.get("height", 1080)
    mon_x = primary_mon.get("x", 0)
    mon_y = primary_mon.get("y", 0)

    drawers = {
        "sidebar": (mon_x + mon_w - 400, mon_y, 400, mon_h),
        "utilities": (mon_x + mon_w - 380, mon_y, 380, mon_h),
        "dashboard": (mon_x + (mon_w - 820) // 2, mon_y + (mon_h - 600) // 2, 820, 600),
        "launcher": (mon_x + (mon_w - 640) // 2, mon_y + mon_h - 560, 640, 500),
        "customlauncher": (mon_x + (mon_w - 640) // 2, mon_y + mon_h - 560, 640, 500),
        "clipboard": (mon_x + (mon_w - 640) // 2, mon_y + mon_h - 560, 640, 500),
        "session": (mon_x + (mon_w - 500) // 2, mon_y + (mon_h - 220) // 2, 500, 220),
    }

    for name, (bx, by, bw, bh) in drawers.items():
        try:
            res = subprocess.check_output(
                ["caelestia", "shell", "drawers", "isOpen", name],
                stderr=subprocess.DEVNULL
            ).decode().strip()
            if res == "1" or res.lower() == "true":
                boxes.append(f"{bx},{by} {bw}x{bh}")
        except Exception:
            pass

    # Full monitors
    for m in monitors:
        x, y = m.get("x", 0), m.get("y", 0)
        w, h = m.get("width", 0), m.get("height", 0)
        if w > 0 and h > 0:
            boxes.append(f"{x},{y} {w}x{h}")

    return boxes

if __name__ == "__main__":
    boxes = get_boxes()
    if boxes:
        print("\n".join(boxes))
