-- Applications & Web Apps Shortcuts

local mainMod = "SUPER"

-- Default Application Binaries
local terminal    = os.getenv("HOME") .. "/.config/hypr/scripts/smart-terminal.py"
local browser     = "chromium"
local fileManager = "nautilus"
local editor      = os.getenv("HOME") .. "/.local/bin/editor-launcher"
local spotify     = os.getenv("HOME") .. "/.local/bin/spotify"

----------------------------------------
---- DESKTOP APPLICATIONS --------------
----------------------------------------

-- Terminal (Super + Return)
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { description = "Launch Terminal" })

-- Terminal with Tmux (Super + Alt + Return)
hl.bind(mainMod .. " + ALT + Return", hl.dsp.exec_cmd(terminal .. " -e tmux new-session -A -s main"), { description = "Launch Terminal with Tmux" })

-- Browser (Super + Shift + B or Super + Shift + Return)
hl.bind(mainMod .. " + SHIFT + B",      hl.dsp.exec_cmd(browser), { description = "Launch Browser (Chromium)" })
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(browser), { description = "Launch Browser (Chromium)" })

-- File Manager (Super + Shift + F)
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(fileManager), { description = "Launch File Manager" })

-- Code Editor (Super + Shift + N) -> Zed / Code / Neovim
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(editor), { description = "Launch Code Editor" })

-- Music / Spotify (Super + Shift + M)
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(spotify), { description = "Launch Spotify Music" })

----------------------------------------
---- WEB APPLICATIONS (PWA / Chrome) ---
----------------------------------------

-- AI / ChatGPT (Super + Shift + A)
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(browser .. " --app=https://chatgpt.com/"), { description = "Open ChatGPT" })
hl.bind(mainMod .. " + SHIFT + ALT + A", hl.dsp.exec_cmd(browser .. " --app=https://claude.ai/"), { description = "Open Claude AI" })

-- WhatsApp (Super + Shift + ALT + G)
hl.bind(mainMod .. " + SHIFT + ALT + G", hl.dsp.exec_cmd(browser .. " --app=https://web.whatsapp.com/"), { description = "Open WhatsApp Web" })

-- YouTube (Super + Shift + Y)
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.exec_cmd(browser .. " --app=https://youtube.com/"), { description = "Open YouTube" })

-- X / Twitter (Super + Shift + X)
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd(browser .. " --app=https://x.com/"), { description = "Open X (Twitter)" })
