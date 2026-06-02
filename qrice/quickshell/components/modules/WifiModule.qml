import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    property bool   connected: false
    property string signal:    "0"
    
    // Speed tracking properties
    property string speed:     "0 KB/s"
    property double lastRx:    0

    // The module width will smoothly expand if speed is toggled on and we are connected
    implicitWidth:  wifiIconText.implicitWidth + (Globals.showWifiSpeed && connected ? speedText.implicitWidth + 8 : 0)
    implicitHeight: 30

    Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    function wifiIcon() {
        let s = parseInt(signal)
        if (!connected) return "󰖪" // Clean, centered Wifi-Off slash
        if (s >= 80)    return "󰖩" // Solid Android-style full pie slice
        if (s >= 60)    return "󰤥" 
        if (s >= 40)    return "󰤢" 
        if (s >= 20)    return "󰤟" 
        return "󰤯"
    }

    function signalColor() {
        if (!connected) return Theme.muted
        let s = parseInt(signal)
        if (s >= 60) return Theme.blue
        if (s >= 30) return Theme.yellow
        return Theme.red
    }

    // ── Wifi signal polling ───────────────────────────────
    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | grep '^yes:'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.trim().split(":")
                if (p.length >= 2) {
                    root.connected = true
                    root.signal    = p[1]
                } else {
                    root.connected = false
                    root.signal    = "0"
                }
            }
        }
    }

    // ── Network speed polling ─────────────────────────────
    Process {
        id: speedProc
        command: ["sh", "-c",
            "iface=$(ip route 2>/dev/null | awk '/default/{print $5}' | head -n1); " +
            "[ -n \"$iface\" ] && cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let cur = parseFloat(this.text.trim())
                if (!isNaN(cur) && root.lastRx > 0 && cur >= root.lastRx) {
                    let kb = (cur - root.lastRx) / 1024
                    root.speed = kb > 1024
                        ? (kb / 1024).toFixed(1) + " MB/s"
                        : Math.round(kb) + " KB/s"
                }
                if (!isNaN(cur)) root.lastRx = cur
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiProc.running  = true
            // Only poll for speed if the user actually has the toggle enabled
            if (Globals.showWifiSpeed) {
                speedProc.running = true
            }
        }
    }

    Row {
        id: innerRow
        anchors.centerIn: parent
        spacing: 10

        // ── Clean Icon ───────────────────────────────────────
        Text {
            id: wifiIconText
            anchors.verticalCenter: parent.verticalCenter
            text:  root.wifiIcon()
            color: root.signalColor()
            font.family: Theme.fontFamily
            font.pixelSize: 18

            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // ── Conditional Speed Label ──────────────────────────
        Text {
            id: speedText
            anchors.verticalCenter: parent.verticalCenter
            text: root.speed
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
            
            // Only visible if global setting is true AND we are actually connected to a network
            visible: Globals.showWifiSpeed && root.connected
            opacity: visible ? 1.0 : 0.0

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: wifiMa
        anchors.fill: parent
        anchors.margins: -4 // Gives a slightly larger click target
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Globals.wifiOpen       = !Globals.wifiOpen
            Globals.bluetoothOpen  = false
            Globals.batteryOpen    = false
            Globals.brightnessOpen = false
            Globals.volumeOpen     = false
            Globals.calendarOpen   = false
        }
    }
}