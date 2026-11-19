#!/usr/bin/env python3
import subprocess
import json

def get_installed():
    try:
        out = subprocess.check_output(["pacman", "-Qq"], text=True)
        return set(out.strip().splitlines())
    except Exception:
        return set()

if __name__ == "__main__":
    pkgs = get_installed()
    print(json.dumps(list(pkgs)))
