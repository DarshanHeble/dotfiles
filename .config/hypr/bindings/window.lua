-- Keybindings: Window Management, Layouts, Navigation & Resizing

local mainMod = "SUPER"

------------------------------
---- UNIVERSAL CLIPBOARD -----
------------------------------

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  local class = (window.class or ""):lower()
  if class:match("alacritty") or class:match("kitty") or class:match("foot") or class:match("ghostty") or class:match("wezterm") then
    return true
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function send_clipboard_key(mods, key)
  return function()
    local ok = pcall(function()
      hl.dispatch(hl.dsp.send_shortcut({ mods = mods, key = key }))
    end)
    if not ok then
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
      hl.timer(function()
        hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
      end, { timeout = 25, type = "oneshot" })
    end
  end
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
  return function()
    if active_window_is_terminal() then
      send_clipboard_key(terminal_mods, terminal_key)()
    else
      send_clipboard_key(default_mods, default_key)()
    end
  end
end

------------------------------
------- LAYOUT TOGGLE --------
------------------------------

local function toggle_layout()
  local cur = hl.get_config("general.layout") or "dwindle"
  local next_layout = "dwindle"
  if cur == "dwindle" then
    next_layout = "master"
  elseif cur == "master" then
    next_layout = "scrolling"
  else
    next_layout = "dwindle"
  end
  hl.config({ general = { layout = next_layout } })
  hl.exec_cmd("notify-send -t 1500 -u low -a Hyprland 'Layout: " .. next_layout:upper() .. "' -h string:x-canonical-private-synchronous:layout")
end

------------------------------
---- WINDOW MANAGEMENT --------
------------------------------

-- Close Window (Super + W)
hl.bind(mainMod .. " + W",         hl.dsp.window.close(), { description = "Close Window" })

-- Close All Windows (Ctrl + Alt + Delete)
hl.bind("CTRL + ALT + Delete",     hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/close-all-windows.sh"), { description = "Close All Windows" })

-- Window State & Layout
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo(), { description = "Toggle Pseudo-tile" })
hl.bind(mainMod .. " + L",         toggle_layout, { description = "Toggle Layout (Dwindle / Master / Scrolling)" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("hyprctl dispatch exit"), { description = "Exit Hyprland" })

-- Global Copy / Paste / Cut
hl.bind(mainMod .. " + C", universal_clipboard_shortcut("CTRL", "C", "CTRL SHIFT", "C"), { description = "Copy" })
hl.bind(mainMod .. " + V", universal_clipboard_shortcut("CTRL", "V", "CTRL SHIFT", "V"), { description = "Paste" })
hl.bind(mainMod .. " + X", universal_clipboard_shortcut("CTRL", "X", "CTRL SHIFT", "C"), { description = "Cut" })


hl.bind(mainMod .. " + minus",         hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true, description = "Shrink Window Width" })
hl.bind(mainMod .. " + equal",         hl.dsp.window.resize({ x = 20, y = 0, relative = true }),  { repeating = true, description = "Expand Window Width" })
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true, description = "Shrink Window Height" })
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 20, relative = true }),  { repeating = true, description = "Expand Window Height" })


