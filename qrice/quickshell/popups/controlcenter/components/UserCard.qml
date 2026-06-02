import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../../"

Rectangle {
    id: userCard
    radius: 20
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
    border.width: 1

    // ── NATIVE DATA STATES ──
    property string currentTime: "00:00"
    property string currentDate: "---"
    property string greeting: "Welcome"
    
    property string sysUser: "user"
    property string sysHost: "linux"
    property string sysUptime: "up 0m"
    
    property int batPercent: 100
    property string batStatus: "Unknown"

    // ── REAL-TIME CLOCK ENGINE ──
    Timer {
        interval: 1000
        running: Globals.controlCenterOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date()
            userCard.currentTime = Qt.formatTime(d, "hh:mm")
            userCard.currentDate = Qt.formatDate(d, "ddd, MMM dd")
            
            let h = d.getHours()
            userCard.greeting = h < 12 ? "Good Morning," : h < 18 ? "Good Afternoon," : "Good Evening,"
        }
    }

    // ── SYSTEM TELEMETRY ENGINE ──
    Process {
        id: sysPoller
        command: [
            "sh", "-c", 
            "echo \"$(whoami)|$(hostname)|$(uptime -p | sed 's/up //; s/ hours,/h/; s/ hour,/h/; s/ minutes/m/; s/ minute/m/')|$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1 || echo 100)|$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1 || echo 'AC')\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let data = text.trim().split("|")
                if (data.length >= 5) {
                    userCard.sysUser = data[0]
                    userCard.sysHost = data[1]
                    userCard.sysUptime = data[2]
                    userCard.batPercent = parseInt(data[3]) || 100
                    userCard.batStatus = data[4]
                }
            }
        }
    }

    Timer {
        interval: 60000 
        running: Globals.controlCenterOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: sysPoller.running = true
    }

    // ── MASTER LAYOUT ──
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── LEFT: PFP & IDENTITY ──
        
        // 1. True Circular Profile Picture
        Item {
            width: 56
            height: 56

            // The raw image (Hidden)
            Image {
                id: pfpImage
                anchors.fill: parent
                source: "file:///home/suzaku/Pictures/Untitled.png"
                fillMode: Image.PreserveAspectCrop
                visible: false 
                asynchronous: true
                cache: true
            }

            // The vector mask (Hidden)
            Rectangle {
                id: pfpMask
                anchors.fill: parent
                radius: 28
                color: "black"
                visible: false
            }

            // The engine that stamps the image into the mask
            MultiEffect {
                source: pfpImage
                anchors.fill: parent
                maskEnabled: true
                maskSource: pfpMask
            }

            // The premium border layered on top of the masked image
            Rectangle {
                anchors.fill: parent
                radius: 28
                color: "transparent"
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
                border.width: 1.5
            }

            // Failsafe fallback icon
            Text {
                anchors.centerIn: parent
                text: "󰆚" 
                color: Theme.accent
                font.pixelSize: 26
                visible: pfpImage.status === Image.Error || pfpImage.status === Image.Null
            }
        }

        // 2. Identity Text Stack
        ColumnLayout {
            spacing: 2
            
            Text {
                Layout.fillWidth: true
                text: userCard.greeting
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            
            Text {
                Layout.fillWidth: true
                text: userCard.sysUser + " @ " + userCard.sysHost
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            
            RowLayout {
                spacing: 6
                Text { text: "󰅐"; color: Theme.muted; font.pixelSize: 12 }
                Text {
                    text: "System Uptime: " + userCard.sysUptime
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }

        // ── FLEX BUFFER ──
        Item { Layout.fillWidth: true }

        // ── RIGHT: CLOCK, DATE, & ACTIONS ──
        ColumnLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 8

            // 1. Time & Date Matrix
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 12

                ColumnLayout {
                    spacing: -4
                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: userCard.currentDate
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.capitalization: Font.AllUppercase
                    }
                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: userCard.currentTime
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 32
                        font.weight: Font.Black
                        font.letterSpacing: -1
                    }
                }
            }

            // 2. Battery Pill & Quick Lock
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Rectangle {
                    width: 64
                    height: 24
                    radius: 12
                    color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.4)
                    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.1)
                    border.width: 1
                    clip: true

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: parent.width * (userCard.batPercent / 100)
                        color: {
                            if (userCard.batStatus === "Charging") return Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.25)
                            if (userCard.batPercent <= 20) return Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.25)
                            return Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                        }
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        Text { 
                            text: userCard.batStatus === "Charging" ? "󰂄" : (userCard.batPercent <= 20 ? "󰂃" : "󰁹")
                            color: userCard.batStatus === "Charging" ? Theme.green : (userCard.batPercent <= 20 ? Theme.red : Theme.subtext)
                            font.pixelSize: 12 
                        }
                        Text { 
                            Layout.fillWidth: true
                            text: userCard.batPercent + "%"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                    border.color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.3)
                    border.width: 1

                    Text { anchors.centerIn: parent; text: "󰌾"; color: Theme.red; font.pixelSize: 12 }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        scale: containsMouse ? (pressed ? 0.9 : 1.1) : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                        onClicked: {
                            Globals.controlCenterOpen = false
                            Quickshell.execDetached(["loginctl", "lock-session"])
                        }
                    }
                }
            }
        }
    }
}