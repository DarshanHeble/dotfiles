-- Keybindings: Mouse Actions

local mainMod = "SUPER"

-- Move / resize windows with mainMod + LMB / RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Move Window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize Window" })
