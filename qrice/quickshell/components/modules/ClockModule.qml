import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
    id: clockPill

    width: row.implicitWidth + 22
    height: 30
    radius: 15

    color: mouse.containsMouse
        ? Qt.rgba(
            Theme.accent.r,
            Theme.accent.g,
            Theme.accent.b,
            0.14
        )
        : "transparent"

    border.width: 1

    border.color: mouse.containsMouse
        ? Qt.rgba(
            Theme.accent.r,
            Theme.accent.g,
            Theme.accent.b,
            0.35
        )
        : Qt.rgba(
            Theme.borderColor.r,
            Theme.borderColor.g,
            Theme.borderColor.b,
            0.20
        )

    scale: mouse.containsMouse ? 1.04 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

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

    property string timeText: ""
    property string dateText: ""

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 7

        Text {
            text: "󰥔"

            color: Theme.accent

            font.family: Theme.fontFamily
            font.pixelSize: 14
        }

        Text {
            text: clockPill.timeText

            color: Theme.text

            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Text {
            text: "•"

            color: Theme.subtext
            font.pixelSize: 10
        }

        Text {
            text: clockPill.dateText

            color: Theme.subtext

            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            let now = new Date()

            clockPill.timeText =
                now.toLocaleTimeString([], {
                    hour: "2-digit",
                    minute: "2-digit",
                    hour12: false
                })

            clockPill.dateText =
                now.toLocaleDateString([], {
                    weekday: "short",
                    day: "2-digit",
                    month: "short"
                })
        }

        Component.onCompleted: triggered()
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        onClicked: {
            Globals.calendarOpen = !Globals.calendarOpen

            Globals.wifiOpen = false
            Globals.bluetoothOpen = false
            Globals.batteryOpen = false
            Globals.brightnessOpen = false
            Globals.volumeOpen = false
            Globals.notificationsOpen = false
        }
    }
}