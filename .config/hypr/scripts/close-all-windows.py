#!/usr/bin/env python3
import json
import os
import subprocess

def close_niri():
    try:
        output = subprocess.check_output(["niri", "msg", "-j", "windows"], stderr=subprocess.DEVNULL)
        windows = json.loads(output)
        if not windows:
            return True
        for w in windows:
            wid = w.get("id")
            if wid is not None:
                subprocess.run(
                    ["niri", "msg", "action", "close-window", "--id", str(wid)],
                    check=False,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
        return True
    except Exception:
        return False

def close_hyprland():
    try:
        output = subprocess.check_output(["hyprctl", "-j", "clients"], stderr=subprocess.DEVNULL)
        clients = json.loads(output)
        if not clients:
            return True
        for c in clients:
            addr = c.get("address")
            if addr:
                # Dispatch close via both lua dispatcher and CLI dispatcher
                lua_code = f'hl.dispatch(hl.dsp.window.close({{ address = "{addr}" }}))'
                subprocess.run(
                    ["hyprctl", "eval", lua_code],
                    check=False,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                subprocess.run(
                    ["hyprctl", "dispatch", "closewindow", f"address:{addr}"],
                    check=False,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
        return True
    except Exception:
        return False

def main():
    # If running in Niri
    if os.environ.get("NIRI_SOCKET") or subprocess.run(["pgrep", "-x", "niri"], stdout=subprocess.DEVNULL).returncode == 0:
        if close_niri():
            return

    # If running in Hyprland
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") or subprocess.run(["pgrep", "-x", "Hyprland"], stdout=subprocess.DEVNULL).returncode == 0:
        if close_hyprland():
            return

    # Fallback: try niri then hyprland
    if not close_niri():
        close_hyprland()

if __name__ == "__main__":
    main()
