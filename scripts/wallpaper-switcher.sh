#!/bin/bash

# Updated variables to your current username and repository architecture
WALLPAPER_DIR="/home/saksham/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-thumbnails"
RICE_DIR="/home/saksham/hyprland_backup"

mkdir -p "$CACHE_DIR"

# ── BUILD ROFI THUMBNAIL MENU ──────────────────────────
rofi_string=""
# Fixed: Moved wildcards outside of quotes so bash can actually expand the file extensions
for wall in "$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.jpeg "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.webp "$WALLPAPER_DIR"/*.gif; do
    [ -e "$wall" ] || continue
    filename=$(basename "$wall")
    thumb="$CACHE_DIR/$filename"
    if [ ! -f "$thumb" ]; then
        # fallback to standard ffmpeg if imagemagick isn't present
        if command -v magick &>/dev/null; then
            magick "$wall" -thumbnail 400x400^ -gravity center -extent 400x400 "$thumb"
        else
            ffmpeg -y -i "$wall" -vf "scale=400:400:force_original_aspect_ratio=increase,crop=400:400" "$thumb" &>/dev/null
        fi
    fi
    rofi_string+="$filename\0icon\x1f$thumb\n"
done

choice=$(echo -en "$rofi_string" | rofi -dmenu -i -p "  Pick Wallpaper" -show-icons -theme-str '
    window {
        width: 80%;
        border-radius: 15px;
    }
    listview {
        columns: 5;
        lines: 3;
        spacing: 20px;
    }
    element {
        orientation: vertical;
        padding: 15px;
        border-radius: 10px;
    }
    element-icon { size: 250px; }
    element-text { horizontal-align: 0.5; }
')

[ -z "$choice" ] && exit 1

TARGET="$WALLPAPER_DIR/$choice"

# ── APPLY WALLPAPER ────────────────────────────────────
# Handles both swww and awww legacy binary states cleanly
if ! pgrep -x "awww-daemon" > /dev/null && ! pgrep -x "swww-daemon" > /dev/null; then
    awww-daemon &
    sleep 1
fi

awww img "$TARGET" \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-step 180 \
    --transition-fps 144

# ── GENERATE COLORS WITH PYWAL ─────────────────────────
# Fixed binary call shortcut for standard Arch installation
wal -q -n -i "$TARGET"

[ ! -f "$HOME/.cache/wal/colors.sh" ] && \
    notify-send "Theme Error" "Pywal failed" && exit 1

source "$HOME/.cache/wal/colors.sh"

# ── MAP PYWAL → YOUR VARIABLES ─────────────────────────
WAYBAR_BASE="$background"
WAYBAR_TEXT="$foreground"
WAYBAR_ACCENT="$color4"
WAYBAR_RED="$color1"

ROFI_BG_MAIN="$background"
ROFI_BG_ALT="$color0"
ROFI_FG_MAIN="$foreground"
ROFI_FG_DIM="$color8"
ROFI_ACCENT_PURPLE="$color5"
ROFI_ACCENT_CYAN="$color6"

SWAYNC_BASE="$background"
SWAYNC_MANTLE="$color0"
SWAYNC_TEXT="$foreground"
SWAYNC_ACCENT="$color4"
SWAYNC_CYAN="$color6"

WLOGOUT_TEXT="$foreground"
WLOGOUT_BUTTON_BG="${background}E6"
WLOGOUT_BORDER="${color4}4D"

HYPR_ACTIVE_1="rgb(${color4:1})"
HYPR_ACTIVE_2="rgb(${color6:1})"
HYPR_INACTIVE="rgb(${color8:1})"

# ── WAYBAR ─────────────────────────────────────────────
sed -i "s|@define-color base .*;|@define-color base    $WAYBAR_BASE;|" "$RICE_DIR/waybar/style.css"
sed -i "s|@define-color text .*;|@define-color text    $WAYBAR_TEXT;|" "$RICE_DIR/waybar/style.css"
sed -i "s|@define-color accent .*;|@define-color accent  $WAYBAR_ACCENT;|" "$RICE_DIR/waybar/style.css"
sed -i "s|@define-color red .*;|@define-color red     $WAYBAR_RED;|" "$RICE_DIR/waybar/style.css"
pkill -SIGUSR2 waybar

# ── ROFI ───────────────────────────────────────────────
sed -i "s|bg-main: .*;|bg-main: $ROFI_BG_MAIN;|" "$RICE_DIR/rofi/config.rasi"
sed -i "s|bg-alt: .*;|bg-alt: $ROFI_BG_ALT;|" "$RICE_DIR/rofi/config.rasi"
sed -i "s|fg-main: .*;|fg-main: $ROFI_FG_MAIN;|" "$RICE_DIR/rofi/config.rasi"
sed -i "s|fg-dim: .*;|fg-dim: $ROFI_FG_DIM;|" "$RICE_DIR/rofi/config.rasi"
sed -i "s|accent-purple: .*;|accent-purple: $ROFI_ACCENT_PURPLE;|" "$RICE_DIR/rofi/config.rasi"
sed -i "s|accent-cyan: .*;|accent-cyan: $ROFI_ACCENT_CYAN;|" "$RICE_DIR/rofi/config.rasi"

# ── SWAYNC ─────────────────────────────────────────────
sed -i "s|@define-color base .*;|@define-color base   $SWAYNC_BASE;|" "$RICE_DIR/swaync/style.css"
sed -i "s|@define-color mantle .*;|@define-color mantle $SWAYNC_MANTLE;|" "$RICE_DIR/swaync/style.css"
sed -i "s|@define-color text .*;|@define-color text   $SWAYNC_TEXT;|" "$RICE_DIR/swaync/style.css"
sed -i "s|@define-color accent .*;|@define-color accent $SWAYNC_ACCENT;|" "$RICE_DIR/swaync/style.css"
sed -i "s|@define-color cyan .*;|@define-color cyan   $SWAYNC_CYAN;|" "$RICE_DIR/swaync/style.css"
swaync-client -rs

# ── WLOGOUT ────────────────────────────────────────────

# ── CAVA GRADIENT ──────────────────────────────────────
sed -i "s|gradient_color_1 = .*|gradient_color_1 = '${color1}';|" "$RICE_DIR/cava/config"
sed -i "s|gradient_color_2 = .*|gradient_color_2 = '${color2}';|" "$RICE_DIR/cava/config"
sed -i "s|gradient_color_3 = .*|gradient_color_3 = '${color3}';|" "$RICE_DIR/cava/config"
sed -i "s|gradient_color_4 = .*|gradient_color_4 = '${color4}';|" "$RICE_DIR/cava/config"
sed -i "s|gradient_color_5 = .*|gradient_color_5 = '${color5}';|" "$RICE_DIR/cava/config"
sed -i "s|gradient_color_6 = .*|gradient_color_6 = '${color6}';|" "$RICE_DIR/cava/config"
pkill -USR1 cava

# ── HYPRLAND BORDERS ───────────────────────────────────
(sleep 0.5 && hyprctl eval "hl.config({ general = { col = { active_border = { colors = {'$HYPR_ACTIVE_1', '$HYPR_ACTIVE_2'}, angle = 45 }, inactive_border = { colors = {'$HYPR_INACTIVE'}, angle = 0 } } } })") &

# ── KITTY ──────────────────────────────────────────────
cat "$HOME/.cache/wal/colors-kitty.conf" > "$HOME/.config/kitty/current-theme.conf" 2>/dev/null || true
kill -SIGUSR1 $(pgrep -a kitty | awk '{print $1}') 2>/dev/null

notify-send "Wallpaper & Theme Updated" "Colors extracted from: $choice"