import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../"

Item {
    id: sysMonRoot
    anchors.fill: parent

    // ── TELEMETRY STATE ──
    property int valCpu: 0
    property int valRam: 0
    property int valGpu: 0
    property int valVram: 0
    property int valSwap: 0
    property int valDisk: 0
    property string strTemp: "0.0°C"

    // ── BACKGROUND HARDWARE PARSERS ──
    // 1. CPU, RAM, SWAP
    Process {
        id: procCore
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}' && free | grep Mem | awk '{print $3/$2 * 100}' && free | grep Swap | awk '{if ($2 > 0) print $3/$2 * 100; else print 0}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                if (lines.length >= 1) sysMonRoot.valCpu = Math.max(0, Math.min(100, Math.round(parseFloat(lines[0]) || 0)))
                if (lines.length >= 2) sysMonRoot.valRam = Math.max(0, Math.min(100, Math.round(parseFloat(lines[1]) || 0)))
                if (lines.length >= 3) sysMonRoot.valSwap = Math.max(0, Math.min(100, Math.round(parseFloat(lines[2]) || 0)))
            }
        }
    }

    // 2. GPU & VRAM (Safe fallback if no NVIDIA)
    Process {
        id: procGpu
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,utilization.memory --format=csv,noheader,nounits 2>/dev/null | tr ',' '\n' || echo '0\n0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                if (lines.length >= 1) sysMonRoot.valGpu = Math.max(0, Math.min(100, parseInt(lines[0]) || 0))
                if (lines.length >= 2) sysMonRoot.valVram = Math.max(0, Math.min(100, parseInt(lines[1]) || 0))
            }
        }
    }

    // 3. Disk & Thermals
    Process {
        id: procDisk
        command: ["sh", "-c", "df -h / | awk 'NR==2 {print $5}' | tr -d '%' && sensors 2>/dev/null | grep -iE 'Core 0|Package id 0|Tctl' | awk '{print $4}' | tr -d '+' | head -n 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                if (lines.length >= 1) sysMonRoot.valDisk = Math.max(0, Math.min(100, parseInt(lines[0]) || 0))
                if (lines.length >= 2 && lines[1] !== "") sysMonRoot.strTemp = lines[1]
            }
        }
    }

    Timer {
        interval: 2000
        running: Globals.controlCenterOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            procCore.running = true
            procGpu.running = true
            procDisk.running = true
        }
    }

    // ── MASTER SCROLLABLE CANVAS ──
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: parent.width
            spacing: 20

            // ── HEADER ──
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 12
                
                Text { text: "󰓡"; color: Theme.accent; font.pixelSize: 24 }
                ColumnLayout {
                    spacing: 2
                    Text { text: "Performance Telemetry"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.Bold }
                    Text { text: "Real-time hardware utilization"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                
                // Live Thermal Badge
                Rectangle {
                    height: 28; width: 72; radius: 14
                    color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                    border.color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.3); border.width: 1
                    RowLayout {
                        anchors.centerIn: parent; spacing: 4
                        Text { text: "󰔏"; color: Theme.red; font.pixelSize: 14 }
                        Text { text: sysMonRoot.strTemp; color: Theme.red; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                    }
                }
            }

            // ── 2X2 RADIAL GAUGE MATRIX ──
            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                columns: 2
                columnSpacing: 16
                rowSpacing: 16

                // INLINE RADIAL GAUGE COMPONENT
                component RadialGaugeCard: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    radius: 20
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
                    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
                    border.width: 1

                    property string label
                    property string icon
                    property int value
                    property color accent

                    // Smooth value proxy for animated Canvas painting
                    property real animatedValue: 0
                    Behavior on animatedValue { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                    onValueChanged: animatedValue = value

                    Canvas {
                        id: gaugeCanvas
                        anchors.fill: parent
                        anchors.margins: 16
                        
                        // Force redraw when animation interpolates
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            
                            var cx = width / 2;
                            var cy = height / 2 + 10; // Shift down slightly
                            var r = Math.min(width, height) / 2 - 12; // Radius
                            
                            ctx.lineWidth = 12;
                            ctx.lineCap = "round";
                            
                            // Background Arc (270 degrees)
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0.75 * Math.PI, 2.25 * Math.PI);
                            ctx.strokeStyle = Qt.rgba(parent.accent.r, parent.accent.g, parent.accent.b, 0.15);
                            ctx.stroke();
                            
                            // Foreground Arc (Active Value)
                            var sweepAngle = (parent.animatedValue / 100) * 1.5 * Math.PI;
                            if (sweepAngle > 0) {
                                ctx.beginPath();
                                ctx.arc(cx, cy, r, 0.75 * Math.PI, 0.75 * Math.PI + sweepAngle);
                                ctx.strokeStyle = parent.accent;
                                ctx.stroke();
                            }
                        }
                        
                        // Binding bridge
                        Connections {
                            target: parent
                            function onAnimatedValueChanged() { gaugeCanvas.requestPaint() }
                        }
                    }

                    // Gauge Typography Overlay
                    ColumnLayout {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 10
                        spacing: 2
                        
                        Text { Layout.alignment: Qt.AlignHCenter; text: parent.parent.icon; color: parent.parent.accent; font.pixelSize: 22 }
                        Text { 
                            Layout.alignment: Qt.AlignHCenter; text: Math.round(parent.parent.animatedValue) + "%"
                            color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Black 
                        }
                        Text { 
                            Layout.alignment: Qt.AlignHCenter; text: parent.parent.label
                            color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1; font.capitalization: Font.AllUppercase 
                        }
                    }
                }

                // Grid Nodes
                RadialGaugeCard { label: "CPU"; icon: "󰘚"; value: sysMonRoot.valCpu; accent: Theme.blue }
                RadialGaugeCard { label: "Memory"; icon: "󰍛"; value: sysMonRoot.valRam; accent: Theme.mauve }
                RadialGaugeCard { label: "GPU"; icon: "󰢮"; value: sysMonRoot.valGpu; accent: Theme.green }
                RadialGaugeCard { label: "VRAM"; icon: "󰽉"; value: sysMonRoot.valVram; accent: Theme.peach }
            }

            // ── LINEAR STORAGE & SWAP MODULES ──
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                Layout.preferredHeight: 150
                radius: 20
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
                border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 18

                    // INLINE LINEAR BAR COMPONENT
                    component LinearMonBar: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        property string label
                        property string icon
                        property int value
                        property color accent

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: parent.parent.icon; color: parent.parent.accent; font.pixelSize: 14 }
                            Text { text: parent.parent.label; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
                            Item { Layout.fillWidth: true }
                            Text { text: parent.parent.value + "%"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Black }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 8; radius: 4
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                            
                            Rectangle {
                                height: parent.height; radius: parent.radius; color: parent.parent.accent
                                width: Math.max(parent.height, (parent.width * parent.parent.value) / 100)
                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    LinearMonBar { label: "Root Filesystem"; icon: "󰋊"; value: sysMonRoot.valDisk; accent: Theme.yellow }
                    LinearMonBar { label: "Swap Partition"; icon: "󰾆"; value: sysMonRoot.valSwap; accent: Theme.teal }
                }
            }

            // Explicit bottom spacer to handle the missing bottom padding
            Item { Layout.preferredHeight: 24 }
        }
    }
}