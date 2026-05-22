import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    property bool   connected: false
    property string signal:    "0"
    property string speed:     "0 KB/s"
    property double lastRx:    0

    implicitWidth:  pill.implicitWidth
    implicitHeight: 34

    function wifiIcon() {
        let s = parseInt(signal)
        if (!connected) return "󰤮"
        if (s >= 80)    return "󰤨"
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
            speedProc.running = true
        }
    }

    // ── Pill ─────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        radius: 10
        implicitWidth: pillRow.implicitWidth + 18

        color: wifiMa.containsMouse
            ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 1.0)
            : "transparent"
        border.width: 1
        border.color: wifiMa.containsMouse
            ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.45)
            : "transparent"

        Behavior on color        { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }
        Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            // Wifi icon
            Text {
                text:  root.wifiIcon()
                color: root.signalColor()
                font.family:    Theme.fontFamily
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Speed label — only when hovered
            Text {
                visible: wifiMa.containsMouse && root.connected
                opacity: wifiMa.containsMouse ? 1.0 : 0.0
                text:  root.speed
                color: Theme.subtext
                font.family:    Theme.fontFamily
                font.pixelSize: 11
                font.weight:    Font.Medium
                Layout.alignment: Qt.AlignVCenter

                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: wifiMa
            anchors.fill: parent
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
}