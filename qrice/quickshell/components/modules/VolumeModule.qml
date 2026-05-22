import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../"

Item {
    id: root

    Layout.preferredWidth:
        Globals.showVolumePercent
        ? 60
        : 20

    Layout.preferredHeight: 28

    property string volLevel: "0"
    property bool volMuted: false

    Process {
        id: volProc

        command: [
            "sh",
            "-c",
            "wpctl get-volume @DEFAULT_AUDIO_SINK@"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim()

                root.volMuted =
                    txt.indexOf("MUTED") >= 0

                let match =
                    txt.match(/[0-9]*\\.?[0-9]+/)

                if (match) {
                    root.volLevel =
                        Math.round(
                            parseFloat(match[0]) * 100
                        ).toString()
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: volProc.running = true
    }

    Behavior on Layout.preferredWidth {
        NumberAnimation {
            duration: 200
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            text:
                root.volMuted
                ? "󰖁"
                : (
                    parseInt(root.volLevel) < 30
                    ? "󰕿"
                    : parseInt(root.volLevel) < 70
                    ? "󰖀"
                    : "󰕾"
                )

            color:
                root.volMuted
                ? Theme.muted
                : Theme.mauve

            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Text {
            visible:
                Globals.showVolumePercent

            text:
                root.volLevel + "%"

            color: Theme.subtext

            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
        }
    }

    MouseArea {
        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            Globals.volumeOpen =
                !Globals.volumeOpen

            Globals.wifiOpen = false
            Globals.bluetoothOpen = false
            Globals.batteryOpen = false
            Globals.brightnessOpen = false
            Globals.notificationsOpen = false
            Globals.calendarOpen = false
        }

        onWheel: (wheel) => {
            let cmd =
                wheel.angleDelta.y > 0
                ? "5%+"
                : "5%-"

            Quickshell.execDetached([
                "wpctl",
                "set-volume",
                "@DEFAULT_AUDIO_SINK@",
                cmd
            ])

            volProc.running = true
        }
    }
}