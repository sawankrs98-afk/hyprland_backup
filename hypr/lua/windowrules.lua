hl.window_rule({
    name = "kitty-transparency",
    match = { class = "kitty" },
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

hl.layer_rule({
    name = "qs-popups-flat",
    match = { namespace = "^(qs_status)$" },
    blur = false,
    ignore_alpha = 0.0
})

hl.layer_rule({
    name = "qs-calendar-flat",
    match = { namespace = "^(qs_calendar)$" },
    blur = false,
    ignore_alpha = 0.0
})