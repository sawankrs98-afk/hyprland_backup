import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Rectangle {
    id: root
    
    height: 30
    radius: 15
    color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.88)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.22)
    border.width: 1
    
    implicitWidth: mainLayout.implicitWidth + 24

    property string cpuUsage: "0"
    property string ramUsage: "0"

    // Multi-target lightweight background data collector
    Process {
        id: barPoller
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d. -f1 && free | grep Mem | awk '{print int($3/$2 * 100)}'"]
        stdout: StdioCollector {
            id: barCollector
            onStreamFinished: {
                let lines = barCollector.text.trim().split("\n")
                if (lines.length >= 2) {
                    root.cpuUsage = lines[0].trim()
                    root.ramUsage = lines[1].trim()
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: barPoller.running = true
    }

    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 12

        // ── CPU Group ──
        RowLayout {
            spacing: 5
            Text {
                text: ""
                color: Globals.sysmonOpen ? Theme.accent : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 17
            }
            Text {
                text: root.cpuUsage + "%"
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }

        // ── RAM Group ──
        RowLayout {
            spacing: 5
            Text {
                text: ""
                color: Globals.sysmonOpen ? Theme.teal : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 17
            }
            Text {
                text: root.ramUsage + "%"
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        scale: containsMouse ? (pressed ? 0.94 : 1.04) : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        onClicked: {
            Globals.sysmonOpen = !Globals.sysmonOpen
            
            Globals.wifiOpen = false
            Globals.bluetoothOpen = false
            Globals.batteryOpen = false
            Globals.volumeOpen = false
            Globals.calendarOpen = false
            Globals.brightnessOpen = false
            Globals.notificationsOpen = false
        }
    }

    Connections {
        target: Globals
        function onWifiOpenChanged()          { if (Globals.wifiOpen)          Globals.sysmonOpen = false }
        function onBluetoothOpenChanged()     { if (Globals.bluetoothOpen)     Globals.sysmonOpen = false }
        function onBatteryOpenChanged()       { if (Globals.batteryOpen)       Globals.sysmonOpen = false }
        function onVolumeOpenChanged()        { if (Globals.volumeOpen)        Globals.sysmonOpen = false }
        function onCalendarOpenChanged()      { if (Globals.calendarOpen)      Globals.sysmonOpen = false }
        function onBrightnessOpenChanged()    { if (Globals.brightnessOpen)    Globals.sysmonOpen = false }
        function onNotificationsOpenChanged() { if (Globals.notificationsOpen) Globals.sysmonOpen = false }
    }
}