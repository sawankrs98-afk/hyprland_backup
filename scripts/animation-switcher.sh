#!/bin/bash

choice=$(printf "󰆏  Fluid — Smooth & Organic\n󰇮  Glitch — Digital & Sharp\n󰈸  Zen — Minimal & Focused\n󰚎  Bouncy — Playful & Energetic\n󰓅  Snappy — Fast & Responsive" | \
    rofi -dmenu -i -p "󰡈  Animations" \
    -theme-str '
    window {
        width: 520px;
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
    *"Fluid"*)
        hyprctl eval "
            hl.curve('easeOutExpo', { type = 'bezier', points = { {0.16, 1}, {0.3, 1} } })
            hl.curve('easeInOutQuart', { type = 'bezier', points = { {0.76, 0}, {0.24, 1} } })
            hl.curve('easeOutBack', { type = 'bezier', points = { {0.34, 1.3}, {0.64, 1} } })
            hl.animation({ leaf = 'windows', enabled = true, speed = 5, bezier = 'easeOutExpo' })
            hl.animation({ leaf = 'windowsOut', enabled = true, speed = 4, bezier = 'easeInOutQuart', style = 'popin 85%' })
            hl.animation({ leaf = 'windowsMove', enabled = true, speed = 5, bezier = 'easeOutExpo' })
            hl.animation({ leaf = 'border', enabled = true, speed = 8, bezier = 'easeOutExpo' })
            hl.animation({ leaf = 'borderangle', enabled = true, speed = 6, bezier = 'easeInOutQuart' })
            hl.animation({ leaf = 'fade', enabled = true, speed = 5, bezier = 'easeOutExpo' })
            hl.animation({ leaf = 'fadeOut', enabled = true, speed = 4, bezier = 'easeInOutQuart' })
            hl.animation({ leaf = 'workspaces', enabled = true, speed = 5, bezier = 'easeOutExpo', style = 'slide' })
            hl.animation({ leaf = 'specialWorkspace', enabled = true, speed = 4, bezier = 'easeOutBack', style = 'slidevert' })
        "
        notify-send "Animations" "Fluid — Smooth & Organic" --icon=preferences-system
        ;;

    *"Glitch"*)
        hyprctl eval "
            hl.curve('glitchIn', { type = 'bezier', points = { {0.0, 1.1}, {0.05, 0.95} } })
            hl.curve('glitchOut', { type = 'bezier', points = { {0.95, 0.05}, {1.0, 0.0} } })
            hl.curve('glitchMove', { type = 'bezier', points = { {0.0, 0.0}, {0.0, 1.0} } })
            hl.animation({ leaf = 'windows', enabled = true, speed = 15, bezier = 'glitchIn' })
            hl.animation({ leaf = 'windowsOut', enabled = true, speed = 10, bezier = 'glitchOut', style = 'popin 95%' })
            hl.animation({ leaf = 'windowsMove', enabled = true, speed = 20, bezier = 'glitchMove' })
            hl.animation({ leaf = 'border', enabled = true, speed = 20, bezier = 'glitchMove' })
            hl.animation({ leaf = 'borderangle', enabled = true, speed = 15, bezier = 'glitchIn' })
            hl.animation({ leaf = 'fade', enabled = true, speed = 15, bezier = 'glitchIn' })
            hl.animation({ leaf = 'fadeOut', enabled = true, speed = 8, bezier = 'glitchOut' })
            hl.animation({ leaf = 'workspaces', enabled = true, speed = 12, bezier = 'glitchMove', style = 'slidefade 15%' })
            hl.animation({ leaf = 'specialWorkspace', enabled = true, speed = 10, bezier = 'glitchIn', style = 'slidefade 10%' })
        "
        notify-send "Animations" "Glitch — Digital & Sharp" --icon=preferences-system
        ;;

    *"Zen"*)
        hyprctl eval "
            hl.curve('zenFade', { type = 'bezier', points = { {0.4, 0.0}, {0.6, 1.0} } })
            hl.curve('zenMove', { type = 'bezier', points = { {0.25, 0.1}, {0.25, 1.0} } })
            hl.curve('zenSlow', { type = 'bezier', points = { {0.0, 0.0}, {0.58, 1.0} } })
            hl.animation({ leaf = 'windows', enabled = true, speed = 3, bezier = 'zenFade' })
            hl.animation({ leaf = 'windowsOut', enabled = true, speed = 2.5, bezier = 'zenSlow', style = 'popin 92%' })
            hl.animation({ leaf = 'windowsMove', enabled = true, speed = 3, bezier = 'zenMove' })
            hl.animation({ leaf = 'border', enabled = true, speed = 4, bezier = 'zenSlow' })
            hl.animation({ leaf = 'borderangle', enabled = true, speed = 3, bezier = 'zenFade' })
            hl.animation({ leaf = 'fade', enabled = true, speed = 3, bezier = 'zenFade' })
            hl.animation({ leaf = 'fadeOut', enabled = true, speed = 2, bezier = 'zenSlow' })
            hl.animation({ leaf = 'workspaces', enabled = true, speed = 3, bezier = 'zenMove', style = 'slidefade 60%' })
            hl.animation({ leaf = 'specialWorkspace', enabled = true, speed = 2.5, bezier = 'zenFade', style = 'slidevert' })
        "
        notify-send "Animations" "Zen — Minimal & Focused" --icon=preferences-system
        ;;

    *"Bouncy"*)
        hyprctl eval "
            hl.curve('bounceIn', { type = 'bezier', points = { {0.2, 1.3}, {0.4, 1.0} } })
            hl.curve('bounceOut', { type = 'bezier', points = { {0.2, 0.8}, {0.4, 1.0} } })
            hl.curve('bounceMove', { type = 'bezier', points = { {0.3, 1.2}, {0.4, 1.0} } })
            hl.animation({ leaf = 'windows', enabled = true, speed = 6, bezier = 'bounceIn', style = 'popin 50%' })
            hl.animation({ leaf = 'windowsOut', enabled = true, speed = 5, bezier = 'bounceOut', style = 'popin 80%' })
            hl.animation({ leaf = 'windowsMove', enabled = true, speed = 6, bezier = 'bounceMove' })
            hl.animation({ leaf = 'border', enabled = true, speed = 8, bezier = 'bounceMove' })
            hl.animation({ leaf = 'borderangle', enabled = true, speed = 6, bezier = 'bounceIn' })
            hl.animation({ leaf = 'fade', enabled = true, speed = 5, bezier = 'bounceOut' })
            hl.animation({ leaf = 'fadeOut', enabled = true, speed = 4, bezier = 'bounceOut' })
            hl.animation({ leaf = 'workspaces', enabled = true, speed = 6, bezier = 'bounceMove', style = 'slide' })
            hl.animation({ leaf = 'specialWorkspace', enabled = true, speed = 5, bezier = 'bounceIn', style = 'slidevert' })
        "
        notify-send "Animations" "Bouncy — Playful & Energetic" --icon=preferences-system
        ;;

    *"Snappy"*)
        hyprctl eval "
            hl.curve('snapIn', { type = 'bezier', points = { {0.1, 1.0}, {0.1, 1.0} } })
            hl.curve('snapOut', { type = 'bezier', points = { {0.1, 0.8}, {0.1, 1.0} } })
            hl.curve('snapMove', { type = 'bezier', points = { {0.1, 1.0}, {0.1, 1.0} } })
            hl.animation({ leaf = 'windows', enabled = true, speed = 2, bezier = 'snapIn', style = 'popin 90%' })
            hl.animation({ leaf = 'windowsOut', enabled = true, speed = 2, bezier = 'snapOut', style = 'popin 95%' })
            hl.animation({ leaf = 'windowsMove', enabled = true, speed = 2, bezier = 'snapMove' })
            hl.animation({ leaf = 'border', enabled = true, speed = 3, bezier = 'snapMove' })
            hl.animation({ leaf = 'borderangle', enabled = true, speed = 2, bezier = 'snapIn' })
            hl.animation({ leaf = 'fade', enabled = true, speed = 2, bezier = 'snapIn' })
            hl.animation({ leaf = 'fadeOut', enabled = true, speed = 2, bezier = 'snapOut' })
            hl.animation({ leaf = 'workspaces', enabled = true, speed = 2, bezier = 'snapMove', style = 'slidefade 10%' })
            hl.animation({ leaf = 'specialWorkspace', enabled = true, speed = 2, bezier = 'snapIn', style = 'slidevert' })
        "
        notify-send "Animations" "Snappy — Fast & Responsive" --icon=preferences-system
        ;;
esac