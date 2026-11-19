-- Autostart processes
-- See https://wiki.hypr.land/configuring/core/autostart/

hl.on("hyprland.start", function ()
    hl.exec_cmd("caelestia shell -d")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/autoreload.py")
end)
