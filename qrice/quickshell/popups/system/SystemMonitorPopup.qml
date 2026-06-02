import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: sysmonRoot
    implicitWidth: 360
    implicitHeight: 350

    // ── Core Telemetry Data ───────────────────────────────
    property string cpuUsage:  "0"
    property string cpuTemp:   "0"
    property string dgpuUsage: "0"
    property string dgpuTemp:  "0"
    property string dgpuVram:  "0/0 GB"
    property string igpuUsage: "0"
    property string ramUsage:  "0"
    property string ramRaw:    "0/0 GB"
    property string diskUsage: "0"
    property string diskRaw:   "0/0 GB"

    // ── Advanced Multi-Engine Hardware Poller ────────────
    Process {
        id: sysPoller
        command: [
            "sh", "-c",
            "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d. -f1 && " +
            "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | cut -c1-2 || echo '0' && " +
            "free | grep Mem | awk '{print int($3/$2 * 100)}' && " +
            "free -m | grep Mem | awk '{printf \"%.1f/%.0f GB\\n\", $3/1024, $2/1024}' && " +
            "df / | tail -1 | awk '{print $5}' | tr -d '%' && " +
            "df -h / | tail -1 | awk '{print $3\"/\"$2}' && " +
            "(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo '0') && " +
            "(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo '0') && " +
            "(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | awk '{printf \"%.1f/%.0f GB\\n\", $1/1024, $2/1024}' || echo '0/0 GB') && " +
            "(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo '0')"
        ]
        stdout: StdioCollector {
            id: sysCollector
            onStreamFinished: {
                let lines = sysCollector.text.trim().split("\n")
                if (lines.length >= 10) {
                    sysmonRoot.cpuUsage  = lines[0].trim()
                    sysmonRoot.cpuTemp   = lines[1].trim()
                    sysmonRoot.ramUsage  = lines[2].trim()
                    sysmonRoot.ramRaw    = lines[3].trim()
                    sysmonRoot.diskUsage = lines[4].trim()
                    sysmonRoot.diskRaw   = lines[5].trim()
                    sysmonRoot.dgpuUsage = lines[6].trim()
                    sysmonRoot.dgpuTemp  = lines[7].trim()
                    sysmonRoot.dgpuVram  = lines[8].trim()
                    sysmonRoot.igpuUsage = lines[9].trim()
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sysPoller.running = true
    }

    // ── Master Dashboard Layout ───────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── Header Header ──
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 2
                Text {
                    text: "CORE ARCHITECTURE"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1
                }
                Text {
                    text: "System Telemetry"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 8; height: 8; radius: 4; color: "#2ecc71"
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.4; to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.4; duration: 1000; easing.type: Easing.InOutSine }
                }
            }
        }

        // ── Twin Processing Core Cards (Side-by-Side) ──────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // ── CPU Card ──
            Rectangle {
                Layout.fillWidth: true
                height: 110; radius: 14
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.03)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 0
                    RowLayout {
                        Text { text: ""; color: Theme.accent; font.pixelSize: 18 }
                        Item { Layout.fillWidth: true }
                        Text { text: sysmonRoot.cpuTemp + "°C"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                    }
                    Item { Layout.fillHeight: true }
                    Text { text: "Central Processor"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Text { text: sysmonRoot.cpuUsage + "%"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 22; font.weight: Font.Bold }
                    Item { Layout.fillHeight: true }
                    Rectangle {
                        Layout.fillWidth: true; height: 4; radius: 2; color: Theme.overlay
                        Rectangle {
                            height: parent.height; radius: parent.radius; color: Theme.accent
                            width: (parent.width * parseFloat(sysmonRoot.cpuUsage)) / 100
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // ── Dedicated GPU Card (RTX 4050) ──
            Rectangle {
                Layout.fillWidth: true
                height: 110; radius: 14
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.03)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 0
                    RowLayout {
                        Text { text: "󰢮"; color: Theme.teal; font.pixelSize: 18 }
                        Item { Layout.fillWidth: true }
                        Text { text: sysmonRoot.dgpuTemp + "°C"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                    }
                    Item { Layout.fillHeight: true }
                    Text { text: "NVIDIA VRAM: " + sysmonRoot.dgpuVram; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Medium }
                    Text { text: sysmonRoot.dgpuUsage + "%"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 22; font.weight: Font.Bold }
                    Item { Layout.fillHeight: true }
                    Rectangle {
                        Layout.fillWidth: true; height: 4; radius: 2; color: Theme.overlay
                        Rectangle {
                            height: parent.height; radius: parent.radius; color: Theme.teal
                            width: (parent.width * parseFloat(sysmonRoot.dgpuUsage)) / 100
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }

        // ── Secondary Telemetry Lanes ─────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            // ── Intel iGPU Row ──
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                RowLayout {
                    Text { text: "󰢜   Intel iGPU Load"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                    Item { Layout.fillWidth: true }
                    Text { text: sysmonRoot.igpuUsage + "%"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 4; radius: 2; color: Theme.overlay
                    Rectangle {
                        height: parent.height; radius: parent.radius; color: Theme.subtext
                        width: (parent.width * parseFloat(sysmonRoot.igpuUsage)) / 100
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // ── Memory Row ──
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                RowLayout {
                    Text { text: "   Unified Memory"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                    Item { Layout.fillWidth: true }
                    Text { text: sysmonRoot.ramRaw + " (" + sysmonRoot.ramUsage + "%)"; color: Theme.peach; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 4; radius: 2; color: Theme.overlay
                    Rectangle {
                        height: parent.height; radius: parent.radius; color: Theme.peach
                        width: (parent.width * parseFloat(sysmonRoot.ramUsage)) / 100
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // ── Storage Row ──
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                RowLayout {
                    Text { text: "󰋊   System Storage (/)"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium }
                    Item { Layout.fillWidth: true }
                    Text { text: sysmonRoot.diskRaw + " (" + sysmonRoot.diskUsage + "%)"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 4; radius: 2; color: Theme.overlay
                    Rectangle {
                        height: parent.height; radius: parent.radius; color: Theme.accent
                        width: (parent.width * parseFloat(sysmonRoot.diskUsage)) / 100
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}