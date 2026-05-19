hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/libexec/polkit-kde-authentication-agent-1 &")
    hl.exec_cmd("waybar &")
    hl.exec_cmd("hyprctl dispatch dpms off && sleep 1 && hyprctl dispatch dpms on &")
    hl.exec_cmd("swaync &")
    hl.dsp.exec_cmd("swww-daemon &")
    hl.exec_cmd("warp-taskbar")
    -- Start the idle daemon
    hl.exec_cmd("hypridle")

    -- Start the authentication agent (needed for GUI root passwords)
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)
