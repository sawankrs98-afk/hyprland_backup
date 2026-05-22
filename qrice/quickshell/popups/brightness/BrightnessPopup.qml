import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../"

Rectangle {
    id: root
    
    // Expanded dimensions for a full control center layout
    implicitWidth: 460
    implicitHeight: 300
    
    radius: 20
    color: Theme.surface
    
    border.width: 1
    border.color: Theme.borderColor

    // Core States
    property int brightnessValue: 50
    property bool nightLightEnabled: false
    property bool autoEnabled: false

    // Smooth UI Bindings
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // HIGH-SPEED POLLING
    Process {
        id: brightnessProc
        command: ["sh", "-c", "brightnessctl info | grep -oP '\\d+(?=%)' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(this.text.trim())
                if (!isNaN(v)) {
                    // Only update from backend if the user isn't actively dragging the slider
                    if (!customSliderArea.pressed) {
                        root.brightnessValue = v
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: Globals.brightnessOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: brightnessProc.running = true
    }

    // MAIN LAYOUT SPLIT
    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // ==========================================
        // LEFT COLUMN: Info, Preview, and Toggles
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Header Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: "Display & Color"
                    color: Theme.text
                    font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Black
                }
                
                Text {
                    text: "Manage your screen luminance"
                    color: Theme.muted
                    font.family: Theme.fontFamily; font.pixelSize: 13
                }
            }

            // ADVANCED POLISH: Live Screen Preview Monitor
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Theme.overlay
                border.width: 1; border.color: Theme.borderColor
                clip: true

                // Simulated Screen Glow
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    height: parent.height - 24
                    radius: 8
                    
                    // Color transitions from dark base to bright white/peach based on slider
                    color: root.nightLightEnabled 
                           ? Qt.rgba(Theme.peach.r, Theme.peach.g, Theme.peach.b, 0.2 + (root.brightnessValue / 120))
                           : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1 + (root.brightnessValue / 120))
                    
                    border.width: 4
                    border.color: Theme.surface
                    
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: root.brightnessValue + "%"
                        color: root.brightnessValue > 50 ? Theme.surface : Theme.text
                        font.family: Theme.fontFamily; font.pixelSize: 22; font.weight: Font.Bold
                    }
                }
            }

            // Quick Presets Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Repeater {
                    model: [25, 50, 75, 100]
                    Rectangle {
                        Layout.fillWidth: true; height: 36; radius: 10
                        
                        color: root.brightnessValue === modelData ? (root.nightLightEnabled ? Theme.peach : Theme.blue) : Theme.overlay
                        border.width: 1
                        border.color: root.brightnessValue === modelData ? "transparent" : Theme.borderColor

                        Text {
                            anchors.centerIn: parent
                            text: modelData + "%"
                            color: root.brightnessValue === modelData ? Theme.base : Theme.text
                            font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold
                        }

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.brightnessValue = modelData
                                Quickshell.execDetached(["brightnessctl", "set", modelData + "%"])
                                brightnessProc.running = true
                            }
                        }
                    }
                }
            }

            // Features Row (Night Light / Auto)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Auto Toggle
                Rectangle {
                    Layout.fillWidth: true; height: 48; radius: 12
                    color: root.autoEnabled ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.15) : Theme.overlay
                    border.width: 1; border.color: root.autoEnabled ? Theme.blue : Theme.borderColor
                    
                    RowLayout {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: "󰃠"; color: root.autoEnabled ? Theme.blue : Theme.muted; font.pixelSize: 16 }
                        Text { text: "Auto"; color: root.autoEnabled ? Theme.blue : Theme.text; font.pixelSize: 13; font.weight: Font.Bold }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.autoEnabled = !root.autoEnabled
                    }
                }

                // Night Light Toggle
                Rectangle {
                    Layout.fillWidth: true; height: 48; radius: 12
                    color: root.nightLightEnabled ? Qt.rgba(Theme.peach.r, Theme.peach.g, Theme.peach.b, 0.15) : Theme.overlay
                    border.width: 1; border.color: root.nightLightEnabled ? Theme.peach : Theme.borderColor
                    
                    RowLayout {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: "󰖔"; color: root.nightLightEnabled ? Theme.peach : Theme.muted; font.pixelSize: 16 }
                        Text { text: "Night"; color: root.nightLightEnabled ? Theme.peach : Theme.text; font.pixelSize: 13; font.weight: Font.Bold }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.nightLightEnabled = !root.nightLightEnabled
                    }
                }
            }
        }

        // ==========================================
        // RIGHT COLUMN: Custom Mapped Vertical Slider
        // ==========================================
        Rectangle {
            Layout.preferredWidth: 80
            Layout.fillHeight: true
            radius: 20
            color: Theme.overlay
            border.width: 1
            border.color: Theme.borderColor
            clip: true

            // The colored fill that moves up and down
            Rectangle {
                id: sliderFill
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                
                // Perfect mathematical binding: maps 0-100 to actual pixel height
                height: (root.brightnessValue / 100) * parent.height
                
                color: root.nightLightEnabled ? Theme.peach : Theme.blue
                
                // Ultra-smooth snapping
                Behavior on height { 
                    NumberAnimation { duration: customSliderArea.pressed ? 0 : 150; easing.type: Easing.OutCubic } 
                }

                // Inner floating icon
                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.brightnessValue < 20 ? "󰃞" : (root.brightnessValue < 60 ? "󰃟" : "󰃠")
                    color: Theme.base
                    font.family: Theme.fontFamily; font.pixelSize: 28
                }
            }

            // Inactive placeholder icon when slider is low
            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰃞"
                color: Theme.muted
                font.family: Theme.fontFamily; font.pixelSize: 28
                visible: root.brightnessValue < 20
            }

            // THE FIX: Custom Math-Based Touch Area (No backwards slider logic)
            MouseArea {
                id: customSliderArea
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor

                function updateBrightness(mouseY) {
                    // Map physical pixels directly to a 0-100 percentage.
                    // Because mouseY = 0 is the TOP of the element, we invert it so TOP = 100%.
                    let rawPercent = 100 - ((mouseY / parent.height) * 100)
                    
                    // Clamp safely between 1 and 100
                    let clamped = Math.max(1, Math.min(100, Math.round(rawPercent)))
                    
                    root.brightnessValue = clamped
                    Quickshell.execDetached(["brightnessctl", "set", clamped + "%"])
                }

                onPressed: (mouse) => updateBrightness(mouse.y)
                onPositionChanged: (mouse) => {
                    if (pressed) updateBrightness(mouse.y)
                }

                // Native scroll wheel support on the giant slider
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y > 0) {
                        Quickshell.execDetached(["brightnessctl", "set", "+5%"])
                    } else {
                        Quickshell.execDetached(["brightnessctl", "set", "5%-"])
                    }
                    brightnessProc.running = true
                }
            }
        }
    }
}