-- Keybindings: Caelestia Shell, Menus, Lock & System Utilities

local mainMod = "SUPER"

------------------------------
---- CAELESTIA SHELL ---------
------------------------------

-- Desktop context menu
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("caelestia shell desktopmenu toggle"), { description = "Desktop Context Menu" })

-- App Launcher (Super + Space)
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"), { description = "Caelestia Launcher" })

-- Custom Hub Launcher (Super + Alt + Space)
hl.bind(mainMod .. " + ALT + space", hl.dsp.exec_cmd("caelestia shell drawers toggle customlauncher"), { description = "Custom Hub Launcher" })

-- Notification Center & History Sidebar (Super + N)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("caelestia shell drawers toggle sidebar"), { description = "Caelestia Notification Center (Sidebar)" })

-- System Dashboard (Super + Shift + N)
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"), { description = "Caelestia System Dashboard" })

-- Power Menu / Session (Super + Escape)
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("caelestia shell drawers toggle session"), { description = "Caelestia Power Menu" })

-- Lock Screen (Super + Ctrl + L)
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("caelestia shell lock lock"), { description = "Lock Screen" })

-- Wallpaper Selector (Super + Ctrl + Space)
hl.bind(mainMod .. " + CTRL + space", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/wallpaper/select.sh"), { description = "Select Wallpaper" })

-- Keybindings Cheatsheet
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/show-keybindings.sh"), { description = "Show Keybindings" })

-- Clipboard History Manager Drawer (Super + Ctrl + V)
hl.bind(mainMod .. " + CTRL + v", hl.dsp.exec_cmd("caelestia shell drawers toggle clipboard"), { description = "Caelestia Clipboard Manager" })

-- Wi-Fi TUI Manager (Super + Ctrl + W) -> Impala
hl.bind(mainMod .. " + CTRL + w", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/wifi-launcher"), { description = "Wi-Fi Manager (Impala)" })

-- Bluetooth TUI Manager (Super + Ctrl + B) -> bluetui
hl.bind(mainMod .. " + CTRL + b", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/bluetooth-launcher"), { description = "Bluetooth Manager (bluetui)" })

-- Audio Mixer TUI Manager (Super + Ctrl + A) -> wiremix
hl.bind(mainMod .. " + CTRL + a", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/audio-launcher"), { description = "Audio Mixer (wiremix)" })

-- System Monitor TUI Manager (Super + Ctrl + T) -> btop
hl.bind(mainMod .. " + CTRL + t", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/btop-launcher"), { description = "System Monitor (btop)" })

-- Docker / Container Monitor (Super + Ctrl + D) -> lazydocker
hl.bind(mainMod .. " + CTRL + d", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/docker-launcher"), { description = "Container Monitor (lazydocker)" })

-- Disk Usage Analyzer (Super + Ctrl + U) -> gdu
hl.bind(mainMod .. " + CTRL + u", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/disk-launcher"), { description = "Disk Usage Analyzer (gdu)" })

-- Caffeine / Inhibit Idle Toggle (Super + Ctrl + I)
hl.bind(mainMod .. " + CTRL + i", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/caffeine-toggle"), { description = "Toggle Caffeine (Inhibit Idle)" })

-- Night Light / Blue Light Filter Toggle (Super + Ctrl + Y) -> hyprsunset
hl.bind(mainMod .. " + CTRL + y", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/nightlight-toggle"), { description = "Toggle Night Light (hyprsunset)" })

-- Display / Monitor Manager (Super + Alt + M) -> nwg-displays
hl.bind(mainMod .. " + ALT + m", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/display-launcher"), { description = "Display / Monitor Manager" })

-- Screenshots (Smart selection: window snap, full screen, or drag area)
local screenshot_script = os.getenv("HOME") .. "/.config/hypr/scripts/screenshot.sh"
hl.bind("Print",        hl.dsp.exec_cmd(screenshot_script .. " save"), { description = "Screenshot (Save & Copy)" })
hl.bind("CTRL + Print", hl.dsp.exec_cmd(screenshot_script .. " copy"), { description = "Screenshot (Copy only)" })

-- Voxtype Voice-to-Text Dictation (Super + Alt + V or Super + D to toggle, with Caelestia Shell UI toaster notifications)
hl.bind(mainMod .. " + ALT + v", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/voxtype-toggle"), { description = "Toggle Voice Dictation (VoxType)" })
hl.bind(mainMod .. " + d",       hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/voxtype-toggle"), { description = "Toggle Voice Dictation (VoxType)" })


