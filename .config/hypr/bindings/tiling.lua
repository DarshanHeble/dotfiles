-- Keybindings: Tiling, Windows, Workspaces, Groups & Monitors

local mainMod = "SUPER"

-- Helper wrapper for o.bind compatibility
local o = {}
function o.bind(keys, description, dispatcher, options)
  local opts = options or {}
  if description then
    opts.description = description
  end
  if type(dispatcher) == "string" then
    dispatcher = hl.dsp.exec_cmd(dispatcher)
  end
  hl.bind(keys, dispatcher, opts)
end

----------------------------------------
---- WINDOW ACTIONS & SPLIT ------------
----------------------------------------

o.bind("SUPER + W", "Close window", hl.dsp.window.close())
o.bind("CTRL + ALT + DELETE", "Close all windows", os.getenv("HOME") .. "/.config/hypr/scripts/close-all-windows.sh")

o.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
o.bind("SUPER + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
local function toggle_full_width()
  local win = hl.get_active_window()
  if not win then
    return
  end
  if win.fullscreen == 1 then
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
  else
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 1, client = 0 }))
  end
end

local function toggle_fullscreen()
  local win = hl.get_active_window()
  if not win then
    return
  end

  if win.fullscreen ~= 0 then
    hl.dispatch(hl.dsp.window.fullscreen(0))
    if win.floating and win.tags and string.find(win.tags, "was_pinned") then
      hl.dispatch(hl.dsp.window.pin({ window = win }))
      hl.dispatch(hl.dsp.window.tag({ window = win, tag = "-was_pinned" }))
    end
  else
    if win.pinned then
      hl.dispatch(hl.dsp.window.tag({ window = win, tag = "+was_pinned" }))
      hl.dispatch(hl.dsp.window.pin({ window = win }))
    end
    hl.dispatch(hl.dsp.window.fullscreen(0))
  end
end

o.bind("SUPER + F", "Full screen", toggle_fullscreen)
o.bind("SUPER + CTRL + F", "Tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
o.bind("SUPER + ALT + F", "Full width (maximized without hiding bars)", toggle_full_width)
o.bind("SUPER + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")
o.bind("SUPER + ALT + Home", "Save window width", "omarchy-hyprland-window-width save")
o.bind("SUPER + Home", "Restore window width", "omarchy-hyprland-window-width restore")
o.bind("SUPER + L", "Cycle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
o.bind("SUPER + ALT + L", "Cycle workspace layout back", "omarchy-hyprland-workspace-layout-toggle back")
o.bind("XF86Display", "Cycle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

----------------------------------------
---- FOCUS & CURSOR CENTERING ----------
----------------------------------------

local function center_cursor_on_window(win)
  if not win or not win.at or not win.size then
    local act = hl.get_active_window()
    if act and act.at and act.size then
      win = act
    else
      return
    end
  end
  local cx = math.floor(win.at.x + win.size.x / 2)
  local cy = math.floor(win.at.y + win.size.y / 2)
  hl.dispatch(hl.dsp.cursor.move({ x = cx, y = cy }))
end

local function focus_and_center(dir)
  return function()
    hl.dispatch(hl.dsp.focus({ direction = dir }))
    hl.timer(function()
      center_cursor_on_window(hl.get_active_window())
    end, { timeout = 15, type = "oneshot" })
  end
end

-- Automatically center cursor whenever a new window is spawned/opened
hl.on("window.open", function(win)
  hl.timer(function()
    center_cursor_on_window(win or hl.get_active_window())
  end, { timeout = 35, type = "oneshot" })
  hl.timer(function()
    center_cursor_on_window(hl.get_active_window())
  end, { timeout = 100, type = "oneshot" })
end)

o.bind("SUPER + LEFT", "Focus on left window", focus_and_center("l"))
o.bind("SUPER + RIGHT", "Focus on right window", focus_and_center("r"))
o.bind("SUPER + UP", "Focus on above window", focus_and_center("u"))
o.bind("SUPER + DOWN", "Focus on below window", focus_and_center("d"))

----------------------------------------
---- WORKSPACES 1 - 10 -----------------
----------------------------------------

for workspace = 1, 10 do
  local numKey = tostring(workspace % 10)
  o.bind("SUPER + " .. numKey, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. numKey, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + ALT + " .. numKey, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

----------------------------------------
---- SCRATCHPAD & QUAKE CONSOLE --------
----------------------------------------

o.bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
o.bind("SUPER + grave", "Toggle Quake console", hl.dsp.workspace.toggle_special("qconsole"))
o.bind("SUPER + M", "Minimize window to the dock", "omarchy-hyprland-window-minimize")
o.bind("SUPER + SHIFT + grave", "Move window to Quake console", hl.dsp.window.move({ workspace = "special:qconsole", follow = false }))

----------------------------------------
---- WORKSPACE NAVIGATION --------------
----------------------------------------

o.bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "m-1" }))
o.bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous_per_monitor" }))

----------------------------------------
---- MONITORS: MOVE WORKSPACE & WINDOW -
----------------------------------------

o.bind("SUPER + SHIFT + ALT + LEFT", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + ALT + RIGHT", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
o.bind("SUPER + SHIFT + ALT + UP", "Move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
o.bind("SUPER + SHIFT + ALT + DOWN", "Move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))

o.bind("SUPER + SHIFT + CTRL + LEFT", "Move window to left monitor", hl.dsp.window.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + CTRL + RIGHT", "Move window to right monitor", hl.dsp.window.move({ monitor = "r" }))
o.bind("SUPER + SHIFT + CTRL + UP", "Move window to up monitor", hl.dsp.window.move({ monitor = "u" }))
o.bind("SUPER + SHIFT + CTRL + DOWN", "Move window to down monitor", hl.dsp.window.move({ monitor = "d" }))

----------------------------------------
---- WINDOW SWAPPING -------------------
----------------------------------------

o.bind("SUPER + SHIFT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + SHIFT + UP", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + DOWN", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

----------------------------------------
---- ALT + TAB CYCLE & Z-ORDER ---------
----------------------------------------

o.bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
o.bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
o.bind("ALT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())
o.bind("ALT + SHIFT + TAB", "Reveal active window on top", hl.dsp.window.alter_zorder({ mode = "bottom" }))

o.bind("CTRL + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))
o.bind("CTRL + ALT + SHIFT + TAB", "Focus on previous monitor", hl.dsp.focus({ monitor = "-1" }))

----------------------------------------
---- WINDOW RESIZING -------------------
----------------------------------------

o.bind("SUPER + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

o.bind("SUPER + ALT + code:20", "Expand window left a little", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
o.bind("SUPER + ALT + code:21", "Shrink window left a little", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
o.bind("SUPER + SHIFT + ALT + code:20", "Shrink window up a little", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
o.bind("SUPER + SHIFT + ALT + code:21", "Expand window down a little", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))

o.bind("SUPER + CTRL + code:20", "Expand window left a lot", hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
o.bind("SUPER + CTRL + code:21", "Shrink window left a lot", hl.dsp.window.resize({ x = 300, y = 0, relative = true }))
o.bind("SUPER + CTRL + SHIFT + code:20", "Shrink window up a lot", hl.dsp.window.resize({ x = 0, y = -300, relative = true }))
o.bind("SUPER + CTRL + SHIFT + code:21", "Expand window down a lot", hl.dsp.window.resize({ x = 0, y = 300, relative = true }))

----------------------------------------
---- MOUSE ACTIONS ---------------------
----------------------------------------

o.bind("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "m+1" }))
o.bind("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "m-1" }))

o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

----------------------------------------
---- WINDOW GROUPS (TABS) --------------
----------------------------------------

o.bind("SUPER + G", "Toggle window grouping", hl.dsp.group.toggle())
o.bind("SUPER + ALT + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))

o.bind("SUPER + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
o.bind("SUPER + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
o.bind("SUPER + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
o.bind("SUPER + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))

o.bind("SUPER + ALT + TAB", "Next window in group", hl.dsp.group.next())
o.bind("SUPER + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())

o.bind("SUPER + CTRL + LEFT", "Move grouped window focus left", hl.dsp.group.prev())
o.bind("SUPER + CTRL + RIGHT", "Move grouped window focus right", hl.dsp.group.next())

o.bind("SUPER + ALT + mouse_down", "Next window in group", hl.dsp.group.next())
o.bind("SUPER + ALT + mouse_up", "Previous window in group", hl.dsp.group.prev())

for index = 1, 5 do
  o.bind("SUPER + ALT + code:" .. tostring(index + 9), "Switch to group window " .. index, hl.dsp.group.active({ index = index }))
end

----------------------------------------
---- MONITOR SCALING -------------------
----------------------------------------

o.bind("SUPER + SLASH", "Monitor scaling up", "omarchy-hyprland-monitor-scaling up")
o.bind("SUPER + ALT + SLASH", "Monitor scaling down", "omarchy-hyprland-monitor-scaling down")
