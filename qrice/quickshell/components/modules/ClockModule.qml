import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 30

    property string timeText: ""
    property string dateText: ""

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            text: root.timeText
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        Text {
            text: "•"
            color: Theme.subtext
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.dateText
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            let now = new Date()

            root.timeText = now.toLocaleTimeString([], {
                hour: "numeric",
                minute: "2-digit",
                hour12: true
            })

            root.dateText = now.toLocaleDateString([], {
                weekday: "short",
                day: "2-digit",
                month: "short"
            })
        }

        Component.onCompleted: triggered()
    }

    MouseArea {
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