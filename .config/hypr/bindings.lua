-- Keybindings Modular Loader
-- Loads all specific binding modules from ~/.config/hypr/bindings/

local bindings_dir = os.getenv("HOME") .. "/.config/hypr/bindings/"

dofile(bindings_dir .. "tiling.lua")
dofile(bindings_dir .. "window.lua")
dofile(bindings_dir .. "shell.lua")
dofile(bindings_dir .. "workspaces.lua")
dofile(bindings_dir .. "media.lua")
dofile(bindings_dir .. "mouse.lua")
dofile(bindings_dir .. "utilities.lua")
