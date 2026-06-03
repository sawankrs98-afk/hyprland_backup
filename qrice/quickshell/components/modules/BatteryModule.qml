import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    Component.onCompleted: console.log("BATTERY MODULE LOADED")

    implicitHeight: 28
    implicitWidth:  Globals.showBatteryPercent ? 72 : 44

    Layout.preferredHeight: implicitHeight
    Layout.preferredWidth:  implicitWidth

    property int    batteryPercent: 0
    property string batteryStatus:  "Unknown"

    readonly property bool isCharging:  batteryStatus === "Charging" || batteryStatus === "Full"
    readonly property bool isCritical:  batteryPercent <= 15 && !isCharging
    readonly property bool isLow:       batteryPercent <= 30 && !isCharging

    // Color — only the accent elements shift, never the whole module
    readonly property color accentColor: {
        if (isCharging)  return Theme.accent
        if (isCritical)  return Theme.red
        if (isLow)       return Theme.peach
        return Theme.subtext
    }

    Behavior on implicitWidth {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    // ── Backend ───────────────────────────────────────────
    Process {
        id: batteryProc
        command: ["sh", "-c",
            "echo \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)|$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split("|")
                if (parts.length >= 2) {
                    root.batteryPercent = parseInt(parts[0].trim()) || 0
                    root.batteryStatus  = parts[1].trim()
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batteryProc.running = true
    }

    // ── Hover glow ────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width:  parent.width + 8
        height: 26
        radius: 13
        color: Qt.rgba(
            root.accentColor.r,
            root.accentColor.g,
            root.accentColor.b,
            ma.containsMouse ? 0.10 : 0.0
        )
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // ── Content ───────────────────────────────────────────
    RowLayout {
        anchors.centerIn: parent
        spacing: 5

        // Battery icon — drawn as a minimal custom shape
        Item {
            implicitWidth:  20
            implicitHeight: 12
            Layout.alignment: Qt.AlignVCenter

            // Battery body outline
            Rectangle {
                id: batteryBody
                anchors.left:           parent.left
                anchors.verticalCenter: parent.verticalCenter
                width:  17
                height: 10
                radius: 2.5
                color:  "transparent"
                border.color: Qt.rgba(
                    root.accentColor.r,
                    root.accentColor.g,
                    root.accentColor.b,
                    ma.containsMouse ? 1.0 : 0.75
                )
                border.width: 1.5

                Behavior on border.color { ColorAnimation { duration: 200 } }

                // Fill level
                Rectangle {
                    anchors.left:    parent.left
                    anchors.top:     parent.top
                    anchors.bottom:  parent.bottom
                    anchors.margins: 2
                    radius:          1.2

                    width: Math.max(
                        0,
                        (parent.width - 4) * Math.min(1.0, root.batteryPercent / 100)
                    )

                    color: Qt.rgba(
                        root.accentColor.r,
                        root.accentColor.g,
                        root.accentColor.b,
                        0.85
                    )

                    Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation  { duration: 250 } }
                }

                // Charging bolt — centered over the fill
                Text {
                    anchors.centerIn: parent
                    visible:  root.isCharging
                    text:     "󱐋"
                    color:    Theme.accent
                    font.family:    Theme.fontFamily
                    font.pixelSize: 9
                    opacity:  root.isCharging ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on color   { ColorAnimation  { duration: 200 } }
                }
            }

            // Battery nub (positive terminal)
            Rectangle {
                anchors.left:           batteryBody.right
                anchors.verticalCenter: batteryBody.verticalCenter
                anchors.leftMargin:     1
                width:  2
                height: 5
                radius: 1
                color: Qt.rgba(
                    root.accentColor.r,
                    root.accentColor.g,
                    root.accentColor.b,
                    0.6
                )
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        // Percentage — shown when toggled
        Text {
            visible:            Globals.showBatteryPercent
            text:               root.batteryPercent + "%"
            color:              ma.containsMouse ? Theme.text : Theme.subtext
            font.family:        Theme.fontFamily
            font.pixelSize:     11
            font.weight:        Font.Medium
            Layout.alignment:   Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }

    // ── Hit area ──────────────────────────────────────────
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor

        // Subtle press compression
        onPressed:  root.scale = 0.90
        onReleased: root.scale = 1.0

        onClicked: {
            Globals.batteryOpen       = !Globals.batteryOpen
            Globals.wifiOpen          = false
            Globals.bluetoothOpen     = false
            Globals.volumeOpen        = false
            Globals.brightnessOpen    = false
            Globals.notificationsOpen = false
            Globals.calendarOpen      = false
        }
    }

    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
}
