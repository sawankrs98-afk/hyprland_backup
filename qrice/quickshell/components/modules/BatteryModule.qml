import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../"

Item {
    id: root

    Component.onCompleted: {
        console.log("BATTERY MODULE LOADED")
    }

    // Fixed sizing for GlowWrapper compatibility
    implicitHeight: 28
    implicitWidth: Globals.showBatteryPercent ? 60 : 22

    // Retained for backward compatibility in standard layouts
    Layout.preferredHeight: implicitHeight
    Layout.preferredWidth: implicitWidth

    property int batteryPercent: 0
    property string batteryStatus: "Unknown"

    // ── REACTIVE BINDINGS FOR LIVE THEME UPDATES ──
    readonly property string currentIcon: {
        if (batteryStatus === "Charging") return "󰂄"
        if (batteryPercent > 80) return "󰁹"
        if (batteryPercent > 50) return "󰂀"
        if (batteryPercent > 20) return "󰁽"
        return "󰂎"
    }

    readonly property color currentColor: {
        if (batteryStatus === "Charging") return Theme.green
        if (batteryPercent <= 15) return Theme.red
        if (batteryPercent <= 30) return Theme.peach
        return Theme.green
    }

    Process {
        id: batteryProc
        // Safely formats output onto a single line: "100|Charging"
        command: [
            "sh",
            "-c",
            "echo \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)|$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split("|")
                if (parts.length >= 2) {
                    root.batteryPercent = parseInt(parts[0].trim()) || 0
                    root.batteryStatus = parts[1].trim()
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batteryProc.running = true
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.currentIcon
            color: root.currentColor
            font.family: Theme.fontFamily
            font.pixelSize: 18
            
            // Ensures smooth transitions when Matugen theme changes
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            visible: Globals.showBatteryPercent
            text: root.batteryPercent + "%"
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            
            // Ensures smooth transitions when Matugen theme changes
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            Globals.batteryOpen = !Globals.batteryOpen

            Globals.wifiOpen = false
            Globals.bluetoothOpen = false
            Globals.volumeOpen = false
            Globals.brightnessOpen = false
            Globals.notificationsOpen = false
            Globals.calendarOpen = false
            Globals.controlCenterOpen = false
        }
    }
}