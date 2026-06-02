hl.window_rule({
    name = "kitty-transparency",
    match = { class = "kitty" },
    opacity = "0.90 0.80"
})

hl.window_rule({
    name = "spotify-transparency",
    match = { class = "spotify" },
    opacity = "0.90 0.80"
})

hl.window_rule({
    name = "float-apps",
    match = { class = "pavucontrol" },
    float = true
})

hl.window_rule({
    name = "float-polkit",
    match = { class = "polkit-kde-authentication-agent-1" },
    float = true
})

hl.window_rule({
    name = "pip-video",
    match = { title = "Picture-in-Picture" },
    float = true,
    pin = true
})

hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize"
})

hl.layer_rule({
    name = "waybar-blur",
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0.0
})

hl.layer_rule({
    name = "rofi-blur",
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.0
})

hl.layer_rule({
    name = "logout-blur",
    match = { namespace = "logout_dialog" },
    blur = true,
    ignore_alpha = 0.0
})

hl.layer_rule({
    name = "logout-blur-fallback",
    match = { namespace = "wlogout" },
    blur = true,
    ignore_alpha = 0.0
})

hl.layer_rule({
    name = "swaync-blur",
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = 0.0
})

-- Smart Gaps / No gaps and no borders when only one tiled window
--hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
--hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

--hl.window_rule({
    --name = "no-gaps-wtv1",
    --match = { float = false, workspace = "w[tv1]" },
    --border_size = 0,
    --rounding = 0,
--})

--hl.window_rule({
    --name = "no-gaps-f1",
    --match = { float = false, workspace = "f[1]" },
    --border_size = 0,
    --rounding = 0,
--})



-- ######## Window rules ########

-- Disable blur for xwayland context menus
--hl.window_rule({match = {class = "^()$", title = "^()$" },                   no_blur = true })

-- Disable blur for every window
--hl.window_rule({match = {class = ".*" }, no_blur = true })

-- Floating
hl.window_rule({match = {title = "^(Open File)(.*)$" },                      center = true})
hl.window_rule({match = {title = "^(Open File)(.*)$" },                      float = true})
hl.window_rule({match = {title = "^(Select a File)(.*)$" },                  center = true})
hl.window_rule({match = {title = "^(Select a File)(.*)$" },                  float = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },               center = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },               float = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },               size = {"(monitor_w*0.60)", "(monitor_h*0.65)"} })
hl.window_rule({match = {title = "^(Open Folder)(.*)$" },                    center = true})
hl.window_rule({match = {title = "^(Open Folder)(.*)$" },                    float = true})
hl.window_rule({match = {title = "^(Save As)(.*)$" },                        center = true})
hl.window_rule({match = {title = "^(Save As)(.*)$" },                        float = true})
hl.window_rule({match = {title = "^(Library)(.*)$" },                        center = true})
hl.window_rule({match = {title = "^(Library)(.*)$" },                        float = true})
hl.window_rule({match = {title = "^(File Upload)(.*)$" },                    center = true})
hl.window_rule({match = {title = "^(File Upload)(.*)$" },                    float = true})
hl.window_rule({match = {title = "^(.*)(wants to save)$" },                  center = true})
hl.window_rule({match = {title = "^(.*)(wants to save)$" },                  float = true})
hl.window_rule({match = {title = "^(.*)(wants to open)$" },                  center = true})
hl.window_rule({match = {title = "^(.*)(wants to open)$" },                  float = true})
hl.window_rule({match = {class = "^(blueberry\\.py)$" },                     float = true})
hl.window_rule({match = {class = "^(guifetch)$" },                           float = true}) -- FlafyDev/guifetch
hl.window_rule({match = {class = "^(pavucontrol)$" },                        float = true})
hl.window_rule({match = {class = "^(pavucontrol)$" },                        size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(pavucontrol)$" },                        center = true})
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },         float = true})
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },         size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },         center = true})
hl.window_rule({match = {class = "^(nm-connection-editor)$" },               float = true})
hl.window_rule({match = {class = "^(nm-connection-editor)$" },               size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(nm-connection-editor)$" },               center = true})
hl.window_rule({match = {class = ".*plasmawindowed.*" },                     float = true})

-- Move
-- kde-material-you-colors spawns a window when changing dark/light theme. This is to make sure it doesn't interfere at all.
hl.window_rule({match = {class = "^(plasma-changeicons)$" }, float = true})
hl.window_rule({match = {class = "^(plasma-changeicons)$" }, no_initial_focus = true})
hl.window_rule({match = {class = "^(plasma-changeicons)$" }, move = {999999, 999999}})
-- stupid dolphin copy
hl.window_rule({match = {title = "^(Copying — Dolphin)$" }, move = {40, 80}})

-- Tiling
hl.window_rule({match = {class = "^dev\\.warp\\.Warp$" }, tile = true})

-- Picture-in-Picture
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, keep_aspect_ratio = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, move = {"(monitor_w*0.73)", "(monitor_h*0.72)"} })
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, size = {"(monitor_w*0.25)", "(monitor_h*0.25)"} })
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, pin = true})

-- Screen sharing
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, float = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, pin = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" }, move = {"(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)"} })

-- --- Tearing ---
hl.window_rule({match = {title = ".*\\.exe" }, immediate = true})
hl.window_rule({match = {title = ".*minecraft.*" }, immediate = true})
hl.window_rule({match = {class = "^(steam_app).*" }, immediate = true})

-- No shadow for tiled windows
hl.window_rule({match = {float = 0 }, no_shadow = true})
hl.layer_rule({
    name = "quickshell-popups-no-blur",
    match = { namespace = "qs_popup" },
    blur = true
})

-- Smart gaps
hl.workspace_rule({
    workspace = "w[tv1]",
    gaps_out = 0,
    gaps_in = 0,
})

hl.workspace_rule({
    workspace = "f[1]",
    gaps_out = 0,
    gaps_in = 0,
})

-- Smart borders / smart rounding
hl.window_rule({
    name = "smart-gaps-wtv1",
    match = {
        float = false,
        workspace = "w[tv1]",
    },
    border_size = 0,
    rounding = 0,
})

hl.window_rule({
    name = "smart-gaps-f1",
    match = {
        float = false,
        workspace = "f[1]",
    },
    border_size = 0,
    rounding = 0,
})


