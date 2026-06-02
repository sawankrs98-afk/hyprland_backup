import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    property int brightness: 50

    implicitWidth:  row.implicitWidth
    implicitHeight: 30

    function brightnessIcon() {
        if (brightness < 20) return "󰃞"
        if (brightness < 50) return "󰃟"
        if (brightness < 80) return "󰃝"
        return "󰃠"
    }

    function brightnessColor() {
        if (brightness < 25) return Theme.subtext
        if (brightness < 60) return Theme.yellow
        return Theme.peach
    }

    // ── Polling ───────────────────────────────────────────
    Process {
        id: brightnessProc
        command: ["sh", "-c", "brightnessctl info 2>/dev/null | grep -oP '\\d+(?=%)' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(this.text.trim())
                if (!isNaN(v)) root.brightness = v
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: brightnessProc.running = true
    }

    // ── Clean Layout ──────────────────────────────────────
    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Icon
        Text {
            text:  root.brightnessIcon()
            color: root.brightnessColor()
            font.family: Theme.fontFamily
            font.pixelSize: 16
            anchors.verticalCenter: parent.verticalCenter
            
            // Satisfying click bounce
            scale: bMa.pressed ? 0.85 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Percent — Always visible to match Waybar
        Text {
            text:  root.brightness + "%"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: bMa
        anchors.fill: parent
        anchors.margins: -4 // Gives a slightly larger, forgiving click target
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            Globals.brightnessOpen = !Globals.brightnessOpen
            Globals.wifiOpen       = false
            Globals.bluetoothOpen  = false
            Globals.batteryOpen    = false
            Globals.volumeOpen     = false
            Globals.calendarOpen   = false
        }
        
        // Scroll wheel to adjust brightness
        onWheel: (wheel) => {
            let cmd = wheel.angleDelta.y > 0 ? "+5%" : "5%-"
            Quickshell.execDetached(["brightnessctl", "set", cmd])
            brightnessProc.running = true
        }
    }
}