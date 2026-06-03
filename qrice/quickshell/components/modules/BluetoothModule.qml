import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    property bool powered: true
    property bool connected: false
    property string deviceName: ""

    // Perfectly matches the 30px height of the other tray icons
    implicitWidth: btIconText.implicitWidth
    implicitHeight: 30

    // ── Connected device polling ──────────────────────────
    Process {
        id: connectedProc
        command: [
            "sh",
            "-c",
            "bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                root.connected = out.length > 0
                root.deviceName = out
            }
        }
    }

    // ── Bluetooth power state polling ─────────────────────
    Process {
        id: powerProc
        command: [
            "sh",
            "-c",
            "bluetoothctl show | grep Powered"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.powered = text.indexOf("yes") >= 0
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            connectedProc.running = true
            powerProc.running = true
        }
    }

    // ── Clean Icon with Animations ────────────────────────
Text {
    id: btIconText
    anchors.centerIn: parent

    text: !root.powered
        ? "󰂲"
        : (root.connected ? "󰂱" : "󰂯")

    color: "#ffffff"

    font.family: Theme.fontFamily
    font.pixelSize: 18

    scale: btMouse.pressed ? 0.85 : 1.0

    Behavior on color {
        ColorAnimation { duration: 200 }
    }

    Behavior on scale {
        NumberAnimation { duration: 100 }
    }
}

    MouseArea {
        id: btMouse
        anchors.fill: parent
        anchors.margins: -4 // Gives a slightly larger, forgiving click target
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            Globals.bluetoothOpen = !Globals.bluetoothOpen

            Globals.wifiOpen = false
            Globals.batteryOpen = false
            Globals.volumeOpen = false
            Globals.brightnessOpen = false
            Globals.notificationsOpen = false
            Globals.calendarOpen = false
        }
    }
}