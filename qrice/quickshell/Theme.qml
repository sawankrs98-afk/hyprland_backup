pragma Singleton
import QtQuick

QtObject {
    // Dynamic Material Colors
    property color base: "#0f1417"
    property color surface: "#1b2023"
    property color overlay: "#252b2d"
    property color text: "#dee3e6"
    property color subtext: "#c0c8cc"
    property color accent: "#89d0ee"
    
    // Fixed Module Accents (Slightly tinted by the wallpaper)
    property color red: "#ffb4ab"
    property color blue: "#89d0ee"
    property color green: "#a6e3a1"
    property color yellow: "#f9e2af"
    property color peach: "#fab387"
    property color teal: "#c4c3ea"
    property color muted: "#40484c"
    
    // Core Layout
    property color borderColor: "#8a9296"
    property int   borderWidth:  1
    property int   barHeight:    42
    property string fontFamily:  "JetBrainsMono Nerd Font Propo"
}