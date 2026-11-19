-- Learn how to configure Hyprland: https://wiki.hypr.land/configuring/

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-------------------------------
---- MODULAR CONFIGURATION ----
-------------------------------
dofile(os.getenv("HOME") .. "/.config/hypr/monitors.lua")
dofile(os.getenv("HOME") .. "/.config/hypr/input.lua")
dofile(os.getenv("HOME") .. "/.config/hypr/looknfeel.lua")
dofile(os.getenv("HOME") .. "/.config/hypr/autostart.lua")
dofile(os.getenv("HOME") .. "/.config/hypr/bindings.lua")
dofile(os.getenv("HOME") .. "/.config/hypr/apps.lua")

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Suppress maximize requests from apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Satty screenshot editor (always float and center)
hl.window_rule({
    name   = "satty-floating",
    match  = { class = ".*satty.*" },
    float  = true,
    center = true,
})

-- IMV image viewer floating window rule
hl.window_rule({
    name   = "imv-floating",
    match  = { class = "^(imv|imv-dir)$" },
    float  = true,
    center = true,
    size   = "1200 800",
})

-- Document viewers floating window rule (Evince, Document Viewer, Zathura, Okular, etc.)
hl.window_rule({
    name   = "document-viewer-floating",
    match  = { class = "^(evince|org.gnome.Evince|zathura|org.kde.okular|qpdfview|sioyek)$" },
    float  = true,
    center = true,
    size   = "1100 850",
})

-- Video players floating window rule (mpv, VLC, Celluloid, Totem, etc.)
hl.window_rule({
    name   = "video-players-floating",
    match  = { class = "^(mpv|io.github.celluloid_player.Celluloid|vlc|org.videolan.vlc|totem)$" },
    float  = true,
    center = true,
    size   = "1280 720",
})

-- Force YouTube / Chromium web apps to tile properly
hl.window_rule({
    name   = "web-apps-tile",
    match  = {
        class = "^(chromium|google-chrome)$",
        title = ".*YouTube.*",
    },
    float  = false,
})

-- Caelestia Presentation Terminal (centered, floating with fixed presentation geometry)
hl.window_rule({
    name   = "caelestia-presentation-terminal",
    match  = { class = "^caelestia-presentation$" },
    float  = true,
    center = true,
    size   = "860 560",
})

-- Floating TUI Windows (Impala Wi-Fi, Bluetuith Bluetooth, etc.)
hl.window_rule({
    name   = "floating-tui-windows",
    match  = { class = "^floating-tui$" },
    float  = true,
    center = true,
    size   = "950 620",
})

-- Global Window Blur & Transparency for All Windows
hl.window_rule({
    name    = "global-window-blur",
    match   = { class = ".*" },
    opacity = "0.92 0.85",
})
