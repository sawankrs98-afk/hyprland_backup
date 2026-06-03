import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    property string timeText: ""
    property string dateText: ""

    implicitWidth:  clockRow.implicitWidth
    implicitHeight: 30

    Row {
        id: clockRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.timeText
            font.family: "Inter"
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Theme.text
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "·"
            font.family: "Inter"
            font.pixelSize: 13
            color: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.45)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.dateText
            font.family: "Inter"
            font.pixelSize: 12
            font.weight: Font.Normal
            color: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.72)
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: update()
        Component.onCompleted: update()
    }

    function update() {
        let now = new Date()
        timeText = now.toLocaleTimeString([], {
            hour: "numeric", minute: "2-digit", hour12: true
        })
        dateText = now.toLocaleDateString([], {
            month: "numeric", day: "2-digit", year: "2-digit"
        })
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Globals.calendarOpen      = !Globals.calendarOpen
            Globals.wifiOpen          = false
            Globals.bluetoothOpen     = false
            Globals.batteryOpen       = false
            Globals.brightnessOpen    = false
            Globals.volumeOpen        = false
            Globals.notificationsOpen = false
        }
    }
}
