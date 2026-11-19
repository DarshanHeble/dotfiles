#!/usr/bin/env python3
import shutil
import json
import subprocess

def check_installed(commands):
    res = {}
    for cmd in commands:
        res[cmd] = shutil.which(cmd) is not None
    return res

if __name__ == "__main__":
    import sys
    cmds = sys.argv[1:]
    print(json.dumps(check_installed(cmds)))
