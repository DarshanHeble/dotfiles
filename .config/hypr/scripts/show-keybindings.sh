#!/usr/bin/env python3
import os
import re
import glob
import subprocess

def scan_hypr_keybindings():
    config_dir = os.path.expanduser("~/.config/hypr")
    
    # Priority order: main hyprland.lua first, then other lua/conf files
    files = []
    main_lua = os.path.join(config_dir, "hyprland.lua")
    if os.path.isfile(main_lua):
        files.append(main_lua)
        
    for f in sorted(glob.glob(os.path.join(config_dir, "*.lua")) + glob.glob(os.path.join(config_dir, "*.conf"))):
        if f not in files and os.path.isfile(f):
            files.append(f)
            
    entries = []
    seen = set()
    
    for path in files:
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()
        except Exception:
            continue
            
        # Parse local variable assignments like terminal = "alacritty", menu = "fuzzel"
        vars = {}
        for line in lines:
            m = re.match(r'^\s*(?:local\s+)?(\w+)\s*=\s*["\']([^"\']+)["\']', line)
            if m:
                vars[m.group(1)] = m.group(2)
        
        prev_comment = ""
        in_workspace_loop = False
        
        for line in lines:
            sline = line.strip()
            
            # Capture preceding comments as descriptions
            if sline.startswith("--") or sline.startswith("#"):
                c = sline.lstrip("-#").strip()
                if c and not c.startswith("---") and not c.startswith("===") and not c.startswith(">>>"):
                    prev_comment = c
                continue
            
            # Detect workspace loops in Lua
            if re.search(r'for\s+\w+\s*=\s*1\s*,\s*10', line):
                in_workspace_loop = True
                ws_items = [
                    ("Super + 1 .. 10", "Switch to Workspace 1–10", "workspace"),
                    ("Super + Shift + 1 .. 10", "Move Window to Workspace 1–10", "movetoworkspace"),
                    ("Super + Shift + Alt + 1 .. 10", "Move Window Silently to Workspace", "movetoworkspacesilent")
                ]
                for k, d, a in ws_items:
                    if k not in seen:
                        seen.add(k)
                        entries.append((k, d, a))
                continue
                
            if in_workspace_loop:
                if sline == "end":
                    in_workspace_loop = False
                continue

            # Parse o.bind("SUPER + RETURN", "Description", action)
            m_o = re.search(r'o\.bind\s*\(\s*["\']([^"\']+)["\']\s*,\s*["\']([^"\']+)["\'](?:\s*,\s*(.+))?', line)
            if m_o:
                key, desc, act = m_o.group(1), m_o.group(2), m_o.group(3) or ""
                key_norm = re.sub(r'\s*\+\s*', ' + ', key).strip()
                if key_norm not in seen:
                    seen.add(key_norm)
                    entries.append((key_norm, desc, act))
                continue

            # Parse standard Hyprland config: bind/bindd/binde/bindm = MODS, KEY, ...
            m_conf = re.match(r'^\s*bind[a-z]*\s*=\s*([^,]+),\s*([^,]+)(?:,\s*([^,]+))?(?:,\s*(.+))?', line)
            if m_conf:
                mods = m_conf.group(1).strip()
                key = m_conf.group(2).strip()
                arg1 = (m_conf.group(3) or "").strip()
                arg2 = (m_conf.group(4) or "").strip()
                
                key_str = f"{mods} + {key}" if mods else key
                key_str = key_str.replace("SUPER", "Super").replace("SHIFT", "Shift").replace("CTRL", "Ctrl").replace("ALT", "Alt")
                
                desc = ""
                action = ""
                if line.strip().startswith("bindd"):
                    desc = arg1
                    action = arg2
                else:
                    action = f"{arg1} {arg2}".strip()
                    desc = prev_comment or action
                
                if key_str not in seen:
                    seen.add(key_str)
                    entries.append((key_str, desc, action))
                prev_comment = ""
                continue

            # Parse hl.bind in Lua
            m_hl = re.match(r'^\s*(?:local\s+\w+\s*=\s*)?hl\.bind\s*\((.+)\)\s*$', line)
            if m_hl:
                inner = m_hl.group(1).strip()
                raw_opts = ""
                m_opts = re.search(r',\s*(\{[^}]*\})\s*$', inner)
                if m_opts:
                    raw_opts = m_opts.group(1)
                    inner = inner[:m_opts.start()].strip()
                
                # Split key part and action part at the first comma outside quotes
                in_quote = False
                quote_char = ""
                comma_idx = -1
                for idx, ch in enumerate(inner):
                    if ch in ('"', "'"):
                        if not in_quote:
                            in_quote = True
                            quote_char = ch
                        elif quote_char == ch:
                            in_quote = False
                    elif ch == "," and not in_quote:
                        comma_idx = idx
                        break
                
                if comma_idx == -1:
                    continue
                    
                raw_key = inner[:comma_idx].strip()
                raw_action = inner[comma_idx+1:].strip()
                
                # Resolve key variables and string concatenations
                key_str = raw_key
                for v, val in vars.items():
                    key_str = re.sub(rf'\b{v}\b', val, key_str)
                key_str = key_str.replace("..", " ").replace('"', "").replace("'", "")
                key_str = re.sub(r'\s*\+\s*', ' + ', key_str)
                key_str = re.sub(r'\s+', ' ', key_str).strip()
                
                parts = [p.strip() for p in key_str.split('+') if p.strip()]
                key_str = " + ".join(parts)
                key_str = key_str.replace("SUPER", "Super").replace("SHIFT", "Shift").replace("CTRL", "Ctrl").replace("ALT", "Alt")
                
                # Friendly key names
                key_str = key_str.replace("code:20", "-").replace("code:21", "+")
                key_str = key_str.replace("minus", "-").replace("equal", "+")
                
                if key_str in seen:
                    continue

                desc = ""
                if raw_opts and "description" in raw_opts:
                    m_desc = re.search(r'description\s*=\s*["\']([^"\']+)["\']', raw_opts)
                    if m_desc:
                        desc = m_desc.group(1)
                
                if not desc:
                    if "terminal" in raw_action:
                        desc = f"Open Terminal ({vars.get('terminal', 'foot')})"
                    elif "menu" in raw_action:
                        desc = f"Application Launcher ({vars.get('menu', 'fuzzel')})"
                    elif "fileManager" in raw_action:
                        desc = f"File Manager ({vars.get('fileManager', 'nautilus')})"
                    elif "window.close" in raw_action:
                        desc = "Close Focused Window"
                    elif "window.float" in raw_action:
                        desc = "Toggle Floating / Tiling Mode"
                    elif "window.fullscreen" in raw_action:
                        desc = "Toggle Fullscreen"
                    elif "universal_clipboard_shortcut" in raw_action or "send_clipboard_key" in raw_action:
                        if "+ C" in key_str:
                            desc = "Universal Copy (Terminal & Apps)"
                        elif "+ V" in key_str:
                            desc = "Universal Paste (Terminal & Apps)"
                        elif "+ X" in key_str:
                            desc = "Universal Cut (Terminal & Apps)"
                    elif "wallpaper" in raw_action:
                        desc = "Select Wallpaper"
                    elif "show-keybindings" in raw_action:
                        desc = "Show All Keybindings (Live Cheat Sheet)"
                    elif "hyprlock" in raw_action or "swaylock" in raw_action:
                        desc = "Lock Screen"
                    elif "exit" in raw_action:
                        desc = "Exit Hyprland"
                    elif "window.pseudo" in raw_action:
                        desc = "Toggle Pseudo Tiling"
                    elif "togglesplit" in raw_action:
                        desc = "Toggle Window Split (Dwindle)"
                    elif "toggle_special" in raw_action:
                        desc = "Toggle Scratchpad Workspace"
                    elif "special:" in raw_action:
                        desc = "Move Window to Scratchpad"
                    elif "focus" in raw_action:
                        m_dir = re.search(r'direction\s*=\s*["\'](\w+)["\']', raw_action)
                        if m_dir:
                            desc = f"Focus Window {m_dir.group(1).title()}"
                        else:
                            desc = "Focus Window / Workspace"
                    elif "window.resize" in raw_action:
                        m_x = re.search(r'x\s*=\s*(-?\d+)', raw_action)
                        m_y = re.search(r'y\s*=\s*(-?\d+)', raw_action)
                        x_val = int(m_x.group(1)) if m_x else 0
                        y_val = int(m_y.group(1)) if m_y else 0
                        if x_val != 0:
                            desc = f"Resize Window Width ({'+' if x_val > 0 else ''}{x_val}px)"
                        elif y_val != 0:
                            desc = f"Resize Window Height ({'+' if y_val > 0 else ''}{y_val}px)"
                        else:
                            desc = "Resize Window"
                    elif "exec_cmd" in raw_action:
                        m_cmd = re.search(r'exec_cmd\s*\(\s*["\']([^"\']+)["\']', raw_action)
                        if m_cmd:
                            desc = m_cmd.group(1)
                
                if not desc and prev_comment:
                    desc = prev_comment
                if not desc:
                    desc = raw_action
                    
                seen.add(key_str)
                entries.append((key_str, desc, raw_action))
                prev_comment = ""
                continue
                
    return entries

def main():
    entries = scan_hypr_keybindings()
    if not entries:
        return

    # Calculate padding for clean alignment
    max_key_len = max(len(k) for k, _, _ in entries)
    col_width = max(max_key_len + 3, 26)

    formatted_lines = []
    item_map = {}
    
    for key, desc, act in entries:
        line_str = f"{key:<{col_width}} │ {desc}"
        formatted_lines.append(line_str)
        item_map[line_str] = (key, desc, act)

    input_text = "\n".join(formatted_lines)
    
    # Run fuzzel in dmenu mode
    proc = subprocess.Popen(
        ["fuzzel", "-d", "--prompt=Shortcuts ❯ ", f"--lines={min(len(formatted_lines), 22)}", "--width=68"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True
    )
    selected, _ = proc.communicate(input=input_text)
    
    if proc.returncode != 0 or not selected.strip():
        return
        
    choice = selected.strip()
    if choice in item_map:
        key, desc, act = item_map[choice]
        is_niri = bool(os.environ.get("NIRI_SOCKET"))
        # Dispatch or execute if appropriate
        if "Open Terminal" in desc:
            subprocess.Popen(["foot"])
        elif "Application Launcher" in desc or "Launcher" in desc:
            subprocess.Popen(["caelestia", "shell", "drawers", "toggle", "launcher"])
        elif "Close Focused Window" in desc or "Close Window" in desc or "Close window" in desc:
            if is_niri:
                subprocess.Popen(["niri", "msg", "action", "close-window"])
            else:
                subprocess.Popen(["hyprctl", "dispatch", "closewindow"])
        elif "Toggle Floating" in desc or "floating" in desc.lower():
            if is_niri:
                subprocess.Popen(["niri", "msg", "action", "toggle-window-floating"])
            else:
                subprocess.Popen(["hyprctl", "dispatch", "togglefloating"])
        elif "Toggle Fullscreen" in desc or "fullscreen" in desc.lower():
            if is_niri:
                subprocess.Popen(["niri", "msg", "action", "fullscreen-window"])
            else:
                subprocess.Popen(["hyprctl", "dispatch", "fullscreen", "0"])
        elif "Lock Screen" in desc:
            subprocess.Popen(["caelestia", "shell", "lock", "lock"])
        elif "Select Wallpaper" in desc:
            subprocess.Popen([os.path.expanduser("~/.config/wallpaper/select.sh")])
        elif "File Manager" in desc:
            subprocess.Popen(["nautilus"])
        elif "Exit" in desc:
            if is_niri:
                subprocess.Popen(["niri", "msg", "action", "quit"])
            else:
                subprocess.Popen(["hyprctl", "dispatch", "exit"])

if __name__ == "__main__":
    main()
