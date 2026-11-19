-- Keybindings: Workspaces & Scratchpad

local mainMod = "SUPER"

-- Workspaces 1 - 10
for workspace = 1, 10 do
    local numKey = tostring(workspace % 10)
    hl.bind(mainMod .. " + " .. numKey,                hl.dsp.focus({ workspace = tostring(workspace) }), { description = "Focus Workspace " .. workspace })
    hl.bind(mainMod .. " + SHIFT + " .. numKey,       hl.dsp.window.move({ workspace = tostring(workspace) }), { description = "Move Window to Workspace " .. workspace })
    hl.bind(mainMod .. " + SHIFT + ALT + " .. numKey, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }), { description = "Move Window to Workspace " .. workspace .. " (No Follow)" })
end

-- Scratchpad (Special workspace: magic)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"), { description = "Toggle Special Workspace (Magic)" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move Window to Special Workspace" })

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Switch to Next Workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Switch to Prev Workspace" })
