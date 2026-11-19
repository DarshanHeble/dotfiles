#!/usr/bin/env python3
"""
Hyprland & Desktop Config Auto-Reloader
Watches ~/.config/hypr and desktop config directories using native Linux inotify.
Whenever any .lua or .conf file is modified and saved, automatically triggers hyprctl reload.
"""

import os
import sys
import time
import struct
import select
import ctypes
import subprocess

libc = ctypes.CDLL("libc.so.6")

# inotify constants
IN_CLOSE_WRITE = 0x00000008
IN_MOVED_TO = 0x00000080
IN_NONBLOCK = 0x00000800
EVENT_FMT = "iIII"
EVENT_SIZE = struct.calcsize(EVENT_FMT)

def watch_configs():
    # Only one instance
    pid_file = "/tmp/hypr-autoreload.pid"
    if os.path.exists(pid_file):
        try:
            with open(pid_file, "r") as f:
                old_pid = int(f.read().strip())
            os.kill(old_pid, 0)
            # Already running
            return
        except (OSError, ValueError):
            pass

    with open(pid_file, "w") as f:
        f.write(str(os.getpid()))

    home = os.path.expanduser("~")
    watch_dirs = [
        os.path.join(home, ".config/hypr"),
        os.path.join(home, ".config/hypr/scripts"),
        os.path.join(home, ".config/hypr/scheme"),
    ]

    fd = libc.inotify_init1(IN_NONBLOCK)
    if fd < 0:
        sys.exit(1)

    wd_to_dir = {}
    for d in watch_dirs:
        if os.path.isdir(d):
            wd = libc.inotify_add_watch(fd, d.encode(), IN_CLOSE_WRITE | IN_MOVED_TO)
            if wd >= 0:
                wd_to_dir[wd] = d

    last_reload = 0.0
    debounce_sec = 0.35

    epoll = select.epoll()
    epoll.register(fd, select.EPOLLIN)

    try:
        while True:
            events = epoll.poll(timeout=2.0)
            if not events:
                continue

            # Read all available events
            should_reload = False
            while True:
                try:
                    data = os.read(fd, 4096)
                    if not data:
                        break
                except BlockingIOError:
                    break

                i = 0
                while i + EVENT_SIZE <= len(data):
                    wd, mask, cookie, length = struct.unpack_from(EVENT_FMT, data, i)
                    name_bytes = data[i + EVENT_SIZE : i + EVENT_SIZE + length]
                    name = name_bytes.decode(errors="ignore").rstrip("\x00")
                    i += EVENT_SIZE + length

                    if name.endswith(".lua") or name.endswith(".conf") or name.endswith(".sh"):
                        should_reload = True

            now = time.time()
            if should_reload and (now - last_reload > debounce_sec):
                last_reload = now
                subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                # Also sync Caelestia scheme to Tmux if scheme changes
                tmux_sync = os.path.expanduser("~/.config/tmux/sync-theme.py")
                if os.path.exists(tmux_sync):
                    subprocess.run(["python3", tmux_sync], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                subprocess.run(
                    ["notify-send", "-t", "1000", "-u", "low", "-a", "Hyprland", "Config Reloaded", "Changes applied immediately"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )

    except KeyboardInterrupt:
        pass
    finally:
        os.close(fd)
        if os.path.exists(pid_file):
            os.remove(pid_file)

if __name__ == "__main__":
    watch_configs()
