-- Keybindings: Multimedia, Brightness & Hardware Keys

-- Laptop multimedia keys (Volume)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Volume Up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, description = "Volume Down" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true, description = "Mute Audio" })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true, description = "Mute Microphone" })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("caelestia shell brightness set +5%"), { locked = true, repeating = true, description = "Brightness Up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("caelestia shell brightness set 5%-"), { locked = true, repeating = true, description = "Brightness Down" })

-- Media player controls
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Media Next" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media Play/Pause" })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media Play/Pause" })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Media Previous" })

-- Hardware Power Button (Short press opens Caelestia power menu)
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("caelestia shell drawers toggle session"), { locked = true, description = "Power Menu (Session)" })
