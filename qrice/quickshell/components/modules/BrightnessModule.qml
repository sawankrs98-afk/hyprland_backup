import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    property int brightness: 50

    implicitWidth:  pill.implicitWidth
    implicitHeight: 34

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

    // ── Pill ─────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        radius: 10
        implicitWidth: pillRow.implicitWidth + 18
        clip: true

        color: bMa.containsMouse
            ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 1.0)
            : "transparent"
        border.width: 1
        border.color: bMa.containsMouse
            ? Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.45)
            : "transparent"

        Behavior on color        { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }

        // Subtle fill bar at bottom — only visible on hover
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.leftMargin: 5
            height: 2
            radius: 1
            width: bMa.containsMouse
                ? (root.brightness / 100) * (pill.width - 10)
                : 0
            color:   root.brightnessColor()
            opacity: 0.65
            Behavior on width   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            // Icon
            Text {
                text:  root.brightnessIcon()
                color: root.brightnessColor()
                font.family:    Theme.fontFamily
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Percent — visible on hover
            Text {
                visible: bMa.containsMouse
                opacity: bMa.containsMouse ? 1.0 : 0.0
                text:  root.brightness + "%"
                color: Theme.text
                font.family:    Theme.fontFamily
                font.pixelSize: 11
                font.weight:    Font.DemiBold
                Layout.alignment: Qt.AlignVCenter
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: bMa
            anchors.fill: parent
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
            onWheel: (wheel) => {
                let cmd = wheel.angleDelta.y > 0 ? "+5%" : "5%-"
                Quickshell.execDetached(["brightnessctl", "set", cmd])
                brightnessProc.running = true
            }
        }
    }
}