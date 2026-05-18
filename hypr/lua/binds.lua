local mainMod = "SUPER"

hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("rofi -show drun"), { on_release = true })
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd("pkill waybar && waybar &"))

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + CONTROL + left", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CONTROL + right", hl.dsp.focus({ workspace = "r+1" }))

hl.bind(mainMod .. " + CONTROL + SHIFT + left", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + right", hl.dsp.window.move({ workspace = "r+1" }))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), { repeating = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })



--hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
--hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m output --clipboard-only"))
--hl.bind(mainMod .. " + CTRL + Print", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))

-- ── BREAKPROOF SCREENSHOTS ──────────────────────────────────────────

-- 1. Region (Interactive Snip)
-- Bound to both Print Screen AND Super + Shift + S as a foolproof fallback
hl.bind("Print", hl.dsp.exec_cmd([[sh -c 'slurp | grim -g - - | wl-copy && notify-send "Screenshot" "Region copied to clipboard"']]))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[sh -c 'slurp | grim -g - - | wl-copy && notify-send "Screenshot" "Region copied to clipboard"']]))

-- 2. Full Output (Entire Screen)
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd([[sh -c 'grim - | wl-copy && notify-send "Screenshot" "Full screen copied to clipboard"']]))

-- 3. Active Window
hl.bind(mainMod .. " + CTRL + Print", hl.dsp.exec_cmd([[sh -c 'hyprctl activewindow -j | jq -r "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])" | grim -g - - | wl-copy && notify-send "Screenshot" "Window copied to clipboard"']]))



hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("bash ~/hyprland_backup/scripts/wallpaper-switcher.sh"))


hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + CTRL + Return", hl.dsp.exec_cmd("[float; center; size 800 600] kitty"))
hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd("[float; center] dolphin"))
hl.bind(mainMod .. " + CTRL + F", hl.dsp.exec_cmd("[float; center] firefox"))

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprctl dispatch centerwindow"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprctl dispatch pin"))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. "+ A", function() os.execute("bash ~/hyprland_backup/scripts/animation-switcher.sh &") end)

hl.bind(mainMod .. "+ L", function() os.execute("bash ~/hyprland_backup/scripts/layout_switcher.sh &") end)