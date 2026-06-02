pragma Singleton
import QtQuick

QtObject {
    // Dynamic Material Colors
    property color base: "{{colors.surface.default.hex}}"
    property color surface: "{{colors.surface_container.default.hex}}"
    property color overlay: "{{colors.surface_container_high.default.hex}}"
    property color text: "{{colors.on_surface.default.hex}}"
    property color subtext: "{{colors.on_surface_variant.default.hex}}"
    property color accent: "{{colors.primary.default.hex}}"
    
    // Fixed Module Accents (Slightly tinted by the wallpaper)
    property color red: "{{colors.error.default.hex}}"
    property color blue: "{{colors.primary.default.hex}}"
    property color green: "#a6e3a1"
    property color yellow: "#f9e2af"
    property color peach: "#fab387"
    property color teal: "{{colors.tertiary.default.hex}}"
    property color muted: "{{colors.outline_variant.default.hex}}"
    
    // Core Layout
    property color borderColor: "{{colors.outline.default.hex}}"
    property int   borderWidth:  1
    property int   barHeight:    42
    property string fontFamily:  "JetBrainsMono Nerd Font Propo"
}