import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../"

Rectangle {
    id: slidersCard
    radius: 20
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
    border.width: 1

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

        // ── INLINE REUSABLE SLIDER CARD SUB-COMPONENT ──
        component CCSliderRow: RowLayout {
            id: sliderRowRoot
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // Component Configuration Api
            property string icon: ""
            property color accentColor: Theme.accent
            property int targetValue: 50
            property var dispatcherAction: function(val){}

            // Left Side: Status Bubble Anchor
            Rectangle {
                id: iconBubble
                width: 38
                height: 38
                radius: 19
                color: Qt.rgba(sliderRowRoot.accentColor.r, sliderRowRoot.accentColor.g, sliderRowRoot.accentColor.b, 0.12)
                border.color: Qt.rgba(sliderRowRoot.accentColor.r, sliderRowRoot.accentColor.g, sliderRowRoot.accentColor.b, 0.3)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: sliderRowRoot.icon
                    color: sliderRowRoot.accentColor
                    font.pixelSize: 18
                }
            }

            // Right Side: Immersive Track Slideway
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: trackTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 20
                    radius: 10
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                    border.width: 1

                    // Active Channel Fill
                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        color: sliderRowRoot.accentColor
                        // Dynamic width boundary protection logic
                        width: Math.max(parent.height, (parent.width * sliderRowRoot.targetValue) / 100)

                        Behavior on width { 
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic } 
                        }
                    }

                    // Numeric Floating Readout
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: sliderRowRoot.targetValue + "%"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Black
                    }
                }

                // Interactive Tracking Area
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    
                    function updateCoordinates(mouse) {
                        if (width <= 0) return
                        let percentage = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                        sliderRowRoot.dispatcherAction(percentage)
                    }

                    onClicked: (mouse) => updateCoordinates(mouse)
                    onPositionChanged: (mouse) => updateCoordinates(mouse)
                }
            }
        }

        // ── HARDWARE MATRIX DISPATCHERS ──

        CCSliderRow {
            icon: "󰕾"
            accentColor: Theme.accent
            targetValue: slidersCard.masterVolume
            dispatcherAction: function(p) {
                slidersCard.masterVolume = p
                Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (p / 100).toFixed(2)])
            }
        }

        CCSliderRow {
            icon: "󰍬"
            accentColor: Theme.teal
            targetValue: slidersCard.microphoneInput
            dispatcherAction: function(p) {
                slidersCard.microphoneInput = p
                Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (p / 100).toFixed(2)])
            }
        }

        CCSliderRow {
            icon: "󰃠"
            accentColor: Theme.peach
            targetValue: slidersCard.displayBrightness
            dispatcherAction: function(p) {
                slidersCard.displayBrightness = p
                Quickshell.execDetached(["brightnessctl", "s", Math.max(1, p) + "%"])
            }
        }
    }
}