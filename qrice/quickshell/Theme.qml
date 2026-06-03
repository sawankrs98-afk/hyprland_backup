pragma Singleton
import QtQuick

QtObject {
    // Dynamic Material Colors
    property color base: "#131318"
    property color surface: "#1f1f25"
    property color overlay: "#2a292f"
    property color text: "#e4e1e9"
    property color subtext: "#c7c5d0"
    property color accent: "#bec2ff"
    
    // Fixed Module Accents (Slightly tinted by the wallpaper)
    property color red: "#ffb4ab"
    property color blue: "#bec2ff"
    property color green: "#a6e3a1"
    property color yellow: "#f9e2af"
    property color peach: "#fab387"
    property color teal: "#e7b9d5"
    property color muted: "#46464f"
    
    // Core Layout
    property color borderColor: "#91909a"
    property int   borderWidth:  1
    property int   barHeight:    42
    property string fontFamily:  "JetBrainsMono Nerd Font Propo"
}