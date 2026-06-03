import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../"

Rectangle {
    id: slidersCard
    radius: 28
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.1)
    border.width: 1
    clip: true

    // ── NATIVE HARDWARE REGISTERS ──
    property int masterVolume: 50
    property int microphoneInput: 50
    property int displayBrightness: 50

    // ── BACKEND CORE POLLERS ──
    Process {
        id: volPoller
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(text.trim())
                if (!isNaN(v)) slidersCard.masterVolume = Math.max(0, Math.min(100, v))
            }
        }
    }

    Process {
        id: micPoller
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{print int($2 * 100)}' || echo 50"]
        stdout: StdioCollector {
            onStreamFinished: {
                let m = parseInt(text.trim())
                if (!isNaN(m)) slidersCard.microphoneInput = Math.max(0, Math.min(100, m))
            }
        }
    }

    Process {
        id: briPoller
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let b = parseInt(text.trim())
                if (!isNaN(b)) slidersCard.displayBrightness = Math.max(1, Math.min(100, b))
            }
        }
    }

    Timer {
        interval: 1500
        running: Globals.controlCenterOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            volPoller.running = true
            micPoller.running = true
            briPoller.running = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        // ── INLINE REUSABLE SLIDER (Android "Split Pill" Style) ──
        component CCSliderRow: Item {
            id: sliderRowRoot
            Layout.fillWidth: true
            Layout.preferredHeight: 48 // Slimmer, matches the screenshot better

            property string iconLow: ""
            property string iconHigh: ""
            property int targetValue: 50
            property var dispatcherAction: function(val){}

            // Bouncy Scale Animation
            scale: sliderMouse.pressed ? 0.97 : 1.0
            Behavior on scale { SpringAnimation { spring: 5.0; damping: 0.6 } }

            // ── Track Background ──
            Rectangle {
                id: trackBg
                anchors.fill: parent
                radius: height / 2
                // Uses the accent color for everything, just lower opacity for the background
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                clip: true

                // Right Icon (High state)
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: sliderRowRoot.iconHigh
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.8)
                    font.pixelSize: 20
                }

                // ── Active Fill ──
                Rectangle {
                    id: trackFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    
                    // Logic ensures the fill stays a pill shape
                    width: Math.max(parent.height, (parent.width * sliderRowRoot.targetValue) / 100)
                    radius: parent.radius
                    color: Theme.accent

                    Behavior on width { 
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic } 
                    }

                    // Left Icon (Low state - cut out of the bright fill)
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: sliderRowRoot.iconLow
                        color: Theme.base 
                        font.pixelSize: 20
                    }
                    
                    // Vertical Thumb Separator (Matches the Android screenshot)
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 24
                        radius: 1
                        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.25)
                        // Hide it if the slider is pushed all the way to 0 to prevent glitching
                        visible: trackFill.width > parent.height + 10 
                    }
                }

                // Interactive Mouse Tracking
                MouseArea {
                    id: sliderMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    
                    function updateCoordinates(mouse) {
                        if (width <= 0) return
                        let percentage = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                        sliderRowRoot.dispatcherAction(percentage)
                    }

                    onClicked: (mouse) => updateCoordinates(mouse)
                    onPositionChanged: (mouse) => {
                        if (pressed) updateCoordinates(mouse)
                    }
                }

                // Scroll Wheel Support
                WheelHandler {
                    target: sliderRowRoot
                    onWheel: (event) => {
                        let step = event.angleDelta.y > 0 ? 5 : -5
                        let newVal = Math.max(0, Math.min(100, sliderRowRoot.targetValue + step))
                        sliderRowRoot.dispatcherAction(newVal)
                    }
                }
            }
        }

        // ── HARDWARE MATRIX DISPATCHERS ──

        CCSliderRow {
            iconLow: "󰕿"
            iconHigh: "󰕾"
            targetValue: slidersCard.masterVolume
            dispatcherAction: function(p) {
                slidersCard.masterVolume = p
                Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (p / 100).toFixed(2)])
            }
        }

        CCSliderRow {
            iconLow: "󰍭"
            iconHigh: "󰍬"
            targetValue: slidersCard.microphoneInput
            dispatcherAction: function(p) {
                slidersCard.microphoneInput = p
                Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (p / 100).toFixed(2)])
            }
        }

        CCSliderRow {
            iconLow: "󰃞"
            iconHigh: "󰃠"
            targetValue: slidersCard.displayBrightness
            dispatcherAction: function(p) {
                slidersCard.displayBrightness = p
                Quickshell.execDetached(["brightnessctl", "s", Math.max(1, p) + "%"])
            }
        }
    }
}