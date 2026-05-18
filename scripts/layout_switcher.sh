#!/bin/bash

choice=$(printf "󰕰  Dwindle — Smart Tiling\n󰖘  Master — Main + Stack\n󰗃  Monocle — Single Focus\n󰙀  Centermaster — Centered\n󰕬  Even — Equal Split" | \
    rofi -dmenu -i -p "󰕰  Layout" \
    -theme-str '
    window {
        width: 500px;
        border-radius: 15px;
        padding: 20px;
    }
    listview {
        lines: 5;
        spacing: 8px;
        padding: 10px;
    }
    element {
        padding: 12px 18px;
        border-radius: 10px;
        font-size: 13px;
    }
    element selected {
        border: 2px solid;
    }
')

[ -z "$choice" ] && exit 1

case "$choice" in
    *"Dwindle"*)
        hyprctl eval "hl.config({ general = { layout = 'dwindle' } })"
        # disable any previous monocle/special state
        hyprctl eval "hl.dsp.fullscreen(0)" 2>/dev/null
        notify-send "Layout" "Dwindle — Smart Tiling" --icon=preferences-system
        ;;
    *"Master"*)
        hyprctl eval "hl.config({ general = { layout = 'master' } })"
        hyprctl eval "hl.dsp.fullscreen(0)" 2>/dev/null
        notify-send "Layout" "Master — Main + Stack" --icon=preferences-system
        ;;
    *"Monocle"*)
        hyprctl eval "hl.config({ general = { layout = 'master' } })"
        hyprctl eval "hl.config({ master = { mfact = 1.0, new_status = 'master' } })"
        notify-send "Layout" "Monocle — Single Focus" --icon=preferences-system
        ;;
    *"Centermaster"*)
        hyprctl eval "hl.config({ general = { layout = 'master' } })"
        hyprctl eval "hl.config({ master = { mfact = 0.5, new_status = 'master', orientation = 'center' } })"
        notify-send "Layout" "Centermaster — Centered Main" --icon=preferences-system
        ;;
    *"Even"*)
        hyprctl eval "hl.config({ general = { layout = 'dwindle' } })"
        hyprctl eval "hl.config({ dwindle = { force_split = 0, preserve_split = true } })"
        notify-send "Layout" "Even — Equal Split" --icon=preferences-system
        ;;
esac
