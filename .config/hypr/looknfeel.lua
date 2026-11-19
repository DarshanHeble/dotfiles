-- Look and Feel configuration
-- Refer to https://wiki.hypr.land/configuring/core/config-options/

-- Dynamically load Caelestia / Material 3 theme scheme colors
local scheme_path = os.getenv("HOME") .. "/.config/hypr/scheme/current.lua"
local scheme = {}
local sf = io.open(scheme_path, "r")
if sf then
    sf:close()
    local ok, res = pcall(dofile, scheme_path)
    if ok and type(res) == "table" then
        scheme = res
    end
end

-- Theme-based border colors
-- Use bright primary / fixed accent for active window focus, muted subtle tone for inactive
local active_border = "rgb(" .. (scheme.primaryFixed or scheme.primary or "ffa7a5") .. ")"
local inactive_border = "rgb(" .. (scheme.surfaceContainerHighest or scheme.outlineVariant or "3e1c16") .. ")"

hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 4,

        border_size = 2,

        col = {
            active_border   = active_border,
            inactive_border = inactive_border,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 20,
        rounding_power = 2,

        -- Window transparency & background blur
        active_opacity   = 0.92,
        inactive_opacity = 0.85,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            new_optimizations = true,
            ignore_opacity    = true,
            popups            = true,
            vibrancy          = 0.2,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/configuring/core/animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

-- Layouts
hl.config({
    dwindle = {
        preserve_split = true,
        smart_split    = false, -- do not base split direction on cursor position
        force_split    = 2,     -- 0 = follow mouse, 1 = always left/top, 2 = always right/bottom
    },
})

hl.config({
    cursor = {
        no_warps                 = false,
        warp_on_change_workspace = 1,     -- warp cursor when changing workspace
        hide_on_key_press        = true,  -- hide cursor as soon as typing begins
        inactive_timeout         = 3,     -- hide cursor after 3 seconds of inactivity
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

-- Misc & Layers
hl.config({
    misc = {
        force_default_wallpaper    = -1,
        disable_hyprland_logo      = false,
        allow_session_lock_restore = true,
    },
})

hl.config({
    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },
})
