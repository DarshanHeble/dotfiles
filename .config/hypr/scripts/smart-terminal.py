#!/usr/bin/env python3
import json
import os
import subprocess

TERMINAL_BINARIES = {
    "foot",
    "footclient",
    "kitty",
    "alacritty",
    "wezterm",
    "gnome-terminal",
    "konsole",
    "xfce4-terminal",
    "xterm",
}

def get_proc_cwd(pid):
    try:
        target = os.readlink(f"/proc/{pid}/cwd")
        if os.path.exists(target):
            return target
    except Exception:
        pass
    return None

def get_children(pid):
    children = []
    task_dir = f"/proc/{pid}/task"
    tids = {pid}
    if os.path.isdir(task_dir):
        try:
            for tid in os.listdir(task_dir):
                if tid.isdigit():
                    tids.add(int(tid))
        except Exception:
            pass

    for entry in os.listdir("/proc"):
        if entry.isdigit():
            cpid = int(entry)
            try:
                with open(f"/proc/{cpid}/stat", "r") as f:
                    fields = f.read().split()
                    ppid = int(fields[3])
                    if ppid in tids or ppid == pid:
                        children.append(cpid)
            except Exception:
                pass
    return sorted(children)

def find_active_terminal_cwd():
    win_pid = None
    win_class = ""
    initial_class = ""

    # Try niri first if running under niri
    if os.environ.get("NIRI_SOCKET"):
        try:
            raw = subprocess.check_output(["niri", "msg", "-j", "focused-window"], timeout=2)
            win = json.loads(raw)
            if win:
                win_pid = win.get("pid")
                win_class = (win.get("app_id") or "").lower()
                initial_class = win_class
        except Exception:
            pass

    if not win_pid:
        try:
            raw = subprocess.check_output(["hyprctl", "activewindow", "-j"], timeout=2)
            win = json.loads(raw)
            if win:
                win_pid = win.get("pid")
                win_class = (win.get("class") or "").lower()
                initial_class = (win.get("initialClass") or "").lower()
        except Exception:
            pass

    if not win_pid:
        return None

    is_term = (
        win_class in TERMINAL_BINARIES
        or initial_class in TERMINAL_BINARIES
        or "terminal" in win_class
        or "foot" in win_class
    )
    if not is_term:
        return None

    # Traverse process tree starting from win_pid to find foreground/child shell process
    visited = set()
    queue = [win_pid]
    procs = []

    while queue:
        curr = queue.pop(0)
        if curr in visited:
            continue
        visited.add(curr)
        procs.append(curr)
        queue.extend(get_children(curr))

    # Inspect from deepest descendant back up to find active working directory
    cwd = None
    for p in reversed(procs):
        p_cwd = get_proc_cwd(p)
        if p_cwd and p_cwd != "/":
            cwd = p_cwd
            break

    if not cwd or cwd == "/":
        cwd = get_proc_cwd(win_pid)
    if not cwd or cwd == "/":
        cwd = os.path.expanduser("~")

    return cwd

def main():
    import sys
    cwd = find_active_terminal_cwd() or os.path.expanduser("~")
    cmd = ["foot", "-D", cwd]
    if len(sys.argv) > 1:
        cmd.extend(sys.argv[1:])
    subprocess.Popen(cmd, start_new_session=True)

if __name__ == "__main__":
    main()
