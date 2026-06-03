import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../"

ColumnLayout {
    id: sysMonRoot
    spacing: 16

    // ── TELEMETRY STATE ──
    property int valCpu: 0
    property string strCpuFreq: "0.0 GHz"
    
    property int valRam: 0
    property string strRamDetail: "0 / 0 GB"
    
    property int valSwap: 0
    property string strSwapDetail: "0 / 0 GB"
    
    property int valDisk: 0
    property string strDiskDetail: "0 / 0 GB"
    
    property string strTemp: "0°C"

    // ── BACKGROUND HARDWARE PARSERS ──
    Process {
        id: procCore
        command: ["sh", "-c", "c=$(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}' | cut -d. -f1); echo \"${c:-0}\"; f=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null | awk '{printf \"%.1f GHz\", $1/1000000}'); [ -z \"$f\" ] && f=$(lscpu | grep -i 'cpu mhz' | head -n 1 | awk '{printf \"%.1f GHz\", $3/1000}'); echo \"${f:-0.0 GHz}\"; free -m | awk '/Mem:/ { printf \"%d|%.1f / %.1f GB\\n\", $3/$2*100, $3/1024, $2/1024 }'; free -m | awk '/Swap:/ { if($2>0) printf \"%d|%.1f / %.1f GB\\n\", $3/$2*100, $3/1024, $2/1024; else print \"0|0 / 0 GB\" }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                if (lines.length >= 4) {
                    sysMonRoot.valCpu = Math.max(0, Math.min(100, parseInt(lines[0]) || 0))
                    sysMonRoot.strCpuFreq = lines[1]
                    
                    let ramData = lines[2].split("|")
                    sysMonRoot.valRam = parseInt(ramData[0]) || 0
                    sysMonRoot.strRamDetail = ramData[1] || "0 / 0 GB"
                    
                    let swapData = lines[3].split("|")
                    sysMonRoot.valSwap = parseInt(swapData[0]) || 0
                    sysMonRoot.strSwapDetail = swapData[1] || "0 / 0 GB"
                }
            }
        }
    }

    Process {
        id: procDisk
        command: ["sh", "-c", "d=$(df -h / | awk 'NR==2 {printf \"%s|%s / %s\\n\", $5, $3, $2}' | tr -d '%'); echo \"${d:-0|0 / 0 GB}\"; t=$(sensors 2>/dev/null | grep -iE 'Core 0|Package id 0|Tctl' | awk '{print $4}' | tr -d '+' | head -n 1); echo \"${t:-0°C}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                if (lines.length >= 2) {
                    let diskData = lines[0].split("|")
                    sysMonRoot.valDisk = parseInt(diskData[0]) || 0
                    sysMonRoot.strDiskDetail = diskData[1] || "0 / 0 GB"
                    sysMonRoot.strTemp = lines[1].split('.')[0] + "°C" 
                }
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
            procDisk.running = true
        }
    }

    // ── COMPACT HEADER ──
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 8
        
        Text { text: "󰓡"; color: Theme.accent; font.pixelSize: 18 }
        Text { text: "System"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Bold }
        Item { Layout.fillWidth: true }
        
        RowLayout {
            spacing: 4
            Text { text: "󰔏"; color: Theme.red; font.pixelSize: 14 }
            Text { text: sysMonRoot.strTemp; color: Theme.red; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold }
        }
    }

    // ── MINIMAL LINEAR METRICS BLOCK ──
    Rectangle {
        Layout.fillWidth: true
        // AUTO-SIZES TO FIT CONTENTS EXACTLY
        implicitHeight: metricsCol.implicitHeight + 40
        radius: 28 
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
        border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.1)
        border.width: 1

        ColumnLayout {
            id: metricsCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 16

            component MinimalMonBar: ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                
                property string label
                property string icon
                property int value
                property string detailText
                property color accent

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { text: parent.parent.icon; color: parent.parent.accent; font.pixelSize: 14 }
                    Text { text: parent.parent.label; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text { 
                        text: parent.parent.detailText
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium 
                    }
                    Text { 
                        text: parent.parent.value + "%"
                        color: parent.parent.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold 
                        Layout.minimumWidth: 35
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 6; radius: 3
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                    clip: true
                    
                    Rectangle {
                        height: parent.height; radius: parent.radius; color: parent.parent.accent
                        width: parent.width * (parent.parent.value / 100)
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                }
            }

            MinimalMonBar { 
                label: "CPU"
                icon: "󰘚"
                value: sysMonRoot.valCpu
                detailText: sysMonRoot.strCpuFreq
                accent: Theme.blue 
            }
            
            MinimalMonBar { 
                label: "Memory"
                icon: "󰍛"
                value: sysMonRoot.valRam
                detailText: sysMonRoot.strRamDetail
                accent: Theme.green 
            }

            MinimalMonBar { 
                label: "Swap"
                icon: "󰾆"
                value: sysMonRoot.valSwap
                detailText: sysMonRoot.strSwapDetail
                accent: Theme.teal 
            }

            MinimalMonBar { 
                label: "Root FS"
                icon: "󰋊"
                value: sysMonRoot.valDisk
                detailText: sysMonRoot.strDiskDetail
                accent: Theme.yellow 
            }
        }
    }
}