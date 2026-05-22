import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../"

Rectangle {
    id: volRoot
    
    // Compact, sleek footprint
    implicitWidth: 360
    implicitHeight: 180
    
    radius: 20
    color: Theme.surface
    
    border.width: 1
    border.color: Theme.borderColor

    // Core States
    property int volLevel: 50
    property bool muted: false
    property bool isDragging: false

    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutQuint } }
    Behavior on border.color { ColorAnimation { duration: 250 } }

    // ==========================================
    // BACKEND POLLING
    // ==========================================
    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.50'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim()
                volRoot.muted = txt.includes("MUTED")
                
                let match = txt.match(/[0-9]*\.?[0-9]+/)
                if (match && !volRoot.isDragging) {
                    volRoot.volLevel = Math.round(parseFloat(match[0]) * 100)
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: Globals.volumeOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: volProc.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ==========================================
        // HEADER (Title & Percentage)
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "Audio Output"
                color: Theme.text
                font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.Bold
            }
            
            Item { Layout.fillWidth: true } // Spacer
            
            Text {
                text: volRoot.muted ? "Muted" : volRoot.volLevel + "%"
                color: volRoot.muted ? Theme.red : Theme.mauve
                font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.Black
            }
        }

        // ==========================================
        // FAT HORIZONTAL SLIDER
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            height: 48 // Thick, touch-friendly pill
            radius: 24
            color: Theme.overlay
            border.width: 1; border.color: Theme.borderColor
            clip: true

            // The Liquid Fill
            Rectangle {
                id: sliderFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                
                // Math-mapped horizontal width
                width: (volRoot.volLevel / 100) * parent.width
                radius: 24
                
                color: volRoot.muted ? Theme.red : Theme.mauve
                
                Behavior on width { 
                    NumberAnimation { duration: volRoot.isDragging ? 0 : 250; easing.type: Easing.OutQuint } 
                }
            }

            // Fixed Icon overlay (always on the left)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                text: volRoot.muted ? "󰖁" : (volRoot.volLevel < 30 ? "󰕿" : (volRoot.volLevel < 70 ? "󰖀" : "󰕾"))
                // Turns white when the fill passes under it
                color: (volRoot.volLevel > 10 || volRoot.muted) ? Theme.base : Theme.muted
                font.pixelSize: 22
                
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Flawless Touch Controller
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor

                function updateVolume(mouseX) {
                    let clampedX = Math.max(0, Math.min(mouseX, parent.width))
                    let rawPercent = (clampedX / parent.width) * 100
                    let targetVal = Math.round(rawPercent)
                    
                    targetVal = Math.max(0, Math.min(100, targetVal))
                    volRoot.volLevel = targetVal
                    
                    // Smart Unmute
                    if (volRoot.muted && targetVal > 0) {
                        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"])
                        volRoot.muted = false
                    }
                    
                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", targetVal + "%"])
                }

                onPressed: (mouse) => { volRoot.isDragging = true; updateVolume(mouse.x) }
                onPositionChanged: (mouse) => { if (pressed) updateVolume(mouse.x) }
                onReleased: { volRoot.isDragging = false; volProc.running = true }

                onWheel: (wheel) => {
                    let cmd = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                    if (volRoot.muted && wheel.angleDelta.y > 0) {
                        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"])
                    }
                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", cmd])
                    volProc.running = true
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ==========================================
        // QUICK ACTIONS (Mute & Mixer)
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Mute Toggle Button
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 12
                color: volRoot.muted ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15) : Theme.overlay
                border.width: 1; border.color: volRoot.muted ? Theme.red : Theme.borderColor
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: volRoot.muted ? "󰖁" : "󰕾"; color: volRoot.muted ? Theme.red : Theme.muted; font.pixelSize: 16 }
                    Text { text: volRoot.muted ? "Muted" : "Mute"; color: volRoot.muted ? Theme.red : Theme.text; font.pixelSize: 12; font.weight: Font.Bold }
                }

                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onPressed: parent.scale = 0.95
                    onReleased: { 
                        parent.scale = 1.0; 
                        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                        volProc.running = true
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }
            }

            // Mixer Launcher Button
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 12
                color: Theme.overlay
                border.width: 1; border.color: Theme.borderColor
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󰟊"; color: Theme.muted; font.pixelSize: 16 }
                    Text { text: "Mixer"; color: Theme.text; font.pixelSize: 12; font.weight: Font.Bold }
                }

                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onPressed: parent.scale = 0.95
                    onReleased: { 
                        parent.scale = 1.0; 
                        Globals.volumeOpen = false;
                        Quickshell.execDetached(["pavucontrol"]) 
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }
            }
        }
    }
}