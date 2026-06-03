import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import "components"
import "popups/status"

ShellRoot {
// ╔══════════════════════════════════════════════════╗
// ║  POPUP SIZES — edit per-popup independently      ║
// ╚══════════════════════════════════════════════════╝
readonly property int popupTopGap:   0  
readonly property int popupRightGap: 6   

// Dynamic media height calculation rule
readonly property int mediaPopupHeight: {
    let players = Mpris.players.values || []

    let count = players.length

    if (count < 1)
        count = 1

    return Math.min(
        750,
        40 + count * 120
    )
}

// Per-popup dimensions — change freely
readonly property var popupSizes: ({
"wifi":          { width: 400, height: 500, isLeft: false, margin: 6 },
"bluetooth":     { width: 400, height: 500, isLeft: false, margin: 6 },
"battery":       { width: 400, height: 500, isLeft: false, margin: 6 },
"volume":        { width: 380, height: 460, isLeft: false, margin: 6 },
"calendar":      { width: 640, height: 400, isLeft: false, margin: 6 },  
"brightness":    { width: 380, height: 300, isLeft: false, margin: 6 },
"notifications": { width: 400, height: 500, isLeft: false, margin: 6 },
"media":         { width: 420, height: 340, isLeft: false,  margin: 200 }, 
"controlcenter": { width: 500, height: 1100, isLeft: false,  margin: 6 }, 
"system":        { width: 360, height: 360, isLeft: false, margin: 320 }   
})

// Resolves which popup is active with clean non-state fallback
readonly property string activePopup: {
if (Globals.mediaOpen)         return "media"
if (Globals.controlCenterOpen) return "controlcenter"
if (Globals.wifiOpen)          return "wifi"
if (Globals.bluetoothOpen)     return "bluetooth"
if (Globals.batteryOpen)       return "battery"
if (Globals.volumeOpen)        return "volume"
if (Globals.calendarOpen)      return "calendar"
if (Globals.brightnessOpen)    return "brightness"
if (Globals.notificationsOpen) return "notifications"
if (Globals.sysmonOpen)        return "system"
return "" // ← Fixed fallback statement
}

// Safe layout bounding checks
readonly property int activePopupWidth:  activePopup ? popupSizes[activePopup].width : 0
readonly property bool activePopupIsLeft: activePopup ? popupSizes[activePopup].isLeft : false
readonly property int activePopupMargin:  activePopup ? popupSizes[activePopup].margin : 0

// Evaluator overrides explicit media dictionary definitions safely
readonly property int activePopupHeight: {
    if (!activePopup)
        return 0
    if (activePopup === "media")
        return mediaPopupHeight
    return popupSizes[activePopup].height
}

// ── Bar ────────────────────────────────────────────────
Variants {
model: Quickshell.screens
PanelWindow {
required property var modelData
screen: modelData
implicitHeight: Theme.barHeight
anchors {
top: true
left: true
right: true
}
color: "transparent"
WlrLayershell.layer: WlrLayer.Top
WlrLayershell.namespace: "qs_topbar"
Bar {
anchors.fill: parent
}
}
}

// ── Status popups ──────────────────────────────────────
Variants {
model: (
Globals.wifiOpen           ||
Globals.bluetoothOpen      ||
Globals.batteryOpen        ||
Globals.volumeOpen         ||
Globals.calendarOpen       ||
Globals.brightnessOpen     ||
Globals.notificationsOpen  ||
Globals.mediaOpen          ||   
Globals.controlCenterOpen  || 
Globals.sysmonOpen
) ? Quickshell.screens : []

PanelWindow {
required property var modelData
screen: modelData
anchors {
top:   true
left:  activePopupIsLeft
right: !activePopupIsLeft
}

Component.onCompleted: {
    console.log(
        "MEDIA HEIGHT:",
        mediaPopupHeight
    )
}
margins {
top: Theme.barHeight - 26
left:  activePopupIsLeft ? activePopupMargin : 0
right: !activePopupIsLeft ? activePopupMargin : 0
}

implicitWidth: activePopupWidth
implicitHeight: activePopupHeight

color: "transparent"
WlrLayershell.layer: WlrLayer.Overlay
WlrLayershell.namespace: "qs_popup"

WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

StatusPopups {
anchors.fill: parent
}
}
}
}