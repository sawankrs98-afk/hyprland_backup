import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../../"

Rectangle {
    id: userCard
    radius: 28
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.6)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
    border.width: 1
    clip: true

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
        spacing: 20

        // ── LEFT: AVATAR (Modern Squircle) ──
        Item {
            width: 68
            height: 68

            Image {
                id: pfpImage
                anchors.fill: parent
                source: "file:///home/suzaku/Pictures/Untitled.png"
                fillMode: Image.PreserveAspectCrop
                visible: false 
                asynchronous: true
                cache: true
            }

            Rectangle {
                id: pfpMask
                anchors.fill: parent
                radius: 22 // Softer squircle shape
                color: "black"
                visible: false
            }

            MultiEffect {
                source: pfpImage
                anchors.fill: parent
                maskEnabled: true
                maskSource: pfpMask
            }

            // Subtle inner ring to separate dark images from dark backgrounds
            Rectangle {
                anchors.fill: parent
                radius: 22
                color: "transparent"
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                border.width: 1
            }

            Text {
                anchors.centerIn: parent
                text: "󰆚" 
                color: Theme.accent
                font.pixelSize: 32
                visible: pfpImage.status === Image.Error || pfpImage.status === Image.Null
            }
        }

        // ── CENTER: IDENTITY ──
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            
            Text {
                Layout.fillWidth: true
                text: userCard.greeting
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
            }
            
            Text {
                Layout.fillWidth: true
                text: userCard.sysUser
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 22
                font.weight: Font.Bold
                font.capitalization: Font.Capitalize
                elide: Text.ElideRight
            }
            
            // Modern Uptime Indicator with glowing dot
            RowLayout {
                spacing: 6
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: Theme.green
                    // Optional subtle glow effect
                    Rectangle {
                        anchors.centerIn: parent
                        width: 12; height: 12; radius: 6
                        color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.25)
                    }
                }
                Text {
                    text: "up " + userCard.sysUptime
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }
        }

        // ── FLEX BUFFER ──
        Item { Layout.fillWidth: true }

        // ── RIGHT: CLOCK & ACTIONS ──
        ColumnLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 10

            // 1. Heavy Clock & Accent Date
            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                spacing: -6
                
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: userCard.currentTime
                    color: Theme.text
                    font.family: "Inter"
                    font.pixelSize: 34
                    font.weight: Font.Black
                    font.letterSpacing: -1.5
                }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: userCard.currentDate
                    color: Theme.accent
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.5
                }
            }

            // 2. Unified Battery & Lock Pill
            Rectangle {
                Layout.alignment: Qt.AlignRight
                width: unifiedPillRow.implicitWidth + 24
                height: 30
                radius: 15
                color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.45)
                border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
                border.width: 1

                RowLayout {
                    id: unifiedPillRow
                    anchors.centerIn: parent
                    spacing: 10

                    // Battery Area
                    RowLayout {
                        spacing: 4
                        Text { 
                            text: userCard.batStatus === "Charging" ? "󰂄" : (userCard.batPercent <= 20 ? "󰂃" : "󰁹")
                            color: userCard.batStatus === "Charging" ? Theme.green : (userCard.batPercent <= 20 ? Theme.red : Theme.subtext)
                            font.pixelSize: 13 
                        }
                        Text { 
                            text: userCard.batPercent + "%"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    // Divider
                    Rectangle {
                        width: 1; height: 14
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                    }

                    // Lock Action
                    Item {
                        width: 16; height: 16
                        Text { 
                            anchors.centerIn: parent
                            text: "󰌾"
                            color: lockHover.hovered ? Theme.red : Theme.subtext
                            font.pixelSize: 13 
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        
                        HoverHandler { id: lockHover }
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6 // Generous click target
                            cursorShape: Qt.PointingHandCursor
                            
                            scale: containsMouse ? (pressed ? 0.8 : 1.15) : 1.0
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
}