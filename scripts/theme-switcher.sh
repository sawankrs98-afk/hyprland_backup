#!/bin/bash

# 1. Define paths
WALLPAPER_DIR="/home/rgs_hyper/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-thumbnails"
RICE_DIR="$HOME/Rice"

# 2. Create the hidden cache folder if it doesn't exist
mkdir -p "$CACHE_DIR"

# 3. Build the visual Rofi menu
rofi_string=""

# Loop through all images in the folder
for wall in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp,gif}; do
    # Skip if no images are found
    [ -e "$wall" ] || continue
    
    filename=$(basename "$wall")
    thumb="$CACHE_DIR/$filename"

    # 4. Generate a square thumbnail ONLY if it hasn't been made yet
    if [ ! -f "$thumb" ]; then
        magick "$wall" -thumbnail 400x400^ -gravity center -extent 400x400 "$thumb"
    fi

    # 5. Format the string so Rofi attaches the thumbnail to the filename
    rofi_string+="$filename\0icon\x1f$thumb\n"
done

# 6. Launch Rofi in Gallery Mode
choice=$(echo -en "$rofi_string" | rofi -dmenu -i -p "  Pick Wallpaper" -show-icons -theme-str '
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
    element-icon { 
        size: 250px; 
    }
    element-text { 
        horizontal-align: 0.5; 
    }
')

# Exit if you press Escape
if [ -z "$choice" ]; then
    exit 1
fi

TARGET="$WALLPAPER_DIR/$choice"

# ==========================================
# APPLY VIA SWWW WITH ANIMATION
# ==========================================

# Make sure swww daemon is running
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon &
    sleep 1
fi

# Apply the wallpaper with the fast grow animation
swww img "$TARGET" \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-step 180 \
    --transition-fps 144

# ==========================================
# GENERATE AND APPLY THEME VIA PYWAL
# ==========================================

# Generate the color palette quietly without setting the wallpaper
wal -q -n -i "$TARGET"

# Source the newly generated pywal colors
source "$HOME/.cache/wal/colors.sh"

# ── MAP PYWAL COLORS TO YOUR VARIABLES ─────────────────
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
sed -i -E "s|color: (#[0-9a-fA-F]+|rgba.*);|color: $WLOGOUT_TEXT;|" "$RICE_DIR/wlogout/style.css"
sed -i -E "s|background-color: (#[0-9a-fA-F]+|rgba.*[^0]);|background-color: $WLOGOUT_BUTTON_BG;|" "$RICE_DIR/wlogout/style.css"
sed -i -E "s|border: (.*)solid (#[0-9a-fA-F]+|rgba.*);|border: \1solid $WLOGOUT_BORDER;|" "$RICE_DIR/wlogout/style.css"

# ── HYPRLAND BORDERS ───────────────────────────────────
(sleep 0.5 && hyprctl eval "hl.config({ general = { col = { active_border = { colors = {'$HYPR_ACTIVE_1', '$HYPR_ACTIVE_2'}, angle = 45 }, inactive_border = { colors = {'$HYPR_INACTIVE'}, angle = 0 } } } })") &

# ── KITTY ──────────────────────────────────────────────
cat "$HOME/.cache/wal/colors-kitty.conf" > "$HOME/.config/kitty/current-theme.conf"
kill -SIGUSR1 $(pgrep -a kitty | awk '{print $1}') 2>/dev/null

notify-send "Wallpaper & Theme Updated" "Applied: $choice"