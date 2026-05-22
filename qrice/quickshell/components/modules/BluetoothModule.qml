import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../"

Rectangle {
    id: root

    Layout.preferredWidth: 28
    Layout.preferredHeight: 28

    radius: 14

    color:
        btMouse.containsMouse
        ? Theme.overlay
        : "transparent"

    border.width: 1

    border.color:
        btMouse.containsMouse
        ? Theme.blue
        : "transparent"

    property bool powered: true
    property bool connected: false
    property string deviceName: ""

    //
    // Connected device
    //
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

                root.connected =
                    out.length > 0

                root.deviceName = out
            }
        }
    }

    //
    // Bluetooth power state
    //
    Process {
        id: powerProc

        command: [
            "sh",
            "-c",
            "bluetoothctl show | grep Powered"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.powered =
                    text.indexOf("yes") >= 0
            }
        }
    }

    //
    // Refresh state
    //
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

    //
    // Hover animation
    //
    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 150
        }
    }

    //
    // Bluetooth icon
    //
    Text {
        anchors.centerIn: parent

        text:
            !root.powered
            ? "󰂲"
            : root.connected
            ? "󰂱"
            : "󰂯"

        color:
            !root.powered
            ? Theme.muted
            : root.connected
            ? Theme.blue
            : Theme.subtext

        font.family: Theme.fontFamily

        font.pixelSize: 16

        font.weight: Font.Bold
    }

    MouseArea {
        id: btMouse

        anchors.fill: parent

        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        onClicked: {
            Globals.bluetoothOpen =
                !Globals.bluetoothOpen

            Globals.wifiOpen = false
            Globals.batteryOpen = false
            Globals.volumeOpen = false
            Globals.brightnessOpen = false
            Globals.notificationsOpen = false
            Globals.calendarOpen = false
        }
    }
}