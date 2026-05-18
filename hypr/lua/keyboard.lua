hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0.5,
        accel_profile = "flat",
        numlock_by_default = true,
        repeat_rate = 35,
        repeat_delay = 250,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            middle_button_emulation = false,
            scroll_factor = 0.2,
        }
    }
})

-- 3 finger swipe left/right → switch workspaces
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- 4 finger swipe up → fullscreen
hl.gesture({
    fingers = 4,
    direction = "up",
    action = "fullscreen"
})