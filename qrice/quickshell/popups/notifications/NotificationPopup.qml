import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: notifRoot

    implicitWidth:  540
    implicitHeight: 740

    // ── State ──────────────────────────────────────────────
    property int    notifCount:     0
    property bool   dndEnabled:     false
    property real   volumeLevel:    0.0
    property bool   volumeMuted:    false
    property real   brightnessLevel: 0.5
    property bool   volDragging:    false
    property bool   brightDragging: false

    // ── swaync: notification count ────────────────────────
    Process {
        id: countProc
        command: ["swaync-client", "--count"]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(text.trim())
                notifRoot.notifCount = isNaN(v) ? 0 : v
            }
        }
    }

    // ── swaync: DND state ─────────────────────────────────
    Process {
        id: dndProc
        command: ["swaync-client", "--get-dnd"]
        stdout: StdioCollector {
            onStreamFinished: {
                notifRoot.dndEnabled = text.trim() === "true"
            }
        }
    }

    // ── Volume (wpctl) ────────────────────────────────────
    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.50'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (notifRoot.volDragging) return
                let t = text.trim()
                notifRoot.volumeMuted = t.includes("[MUTED]")
                let m = t.match(/Volume:\s*([\d.]+)/)
                if (m) notifRoot.volumeLevel = Math.min(1.5, parseFloat(m[1]))
            }
        }
    }

    // ── Brightness (brightnessctl) ────────────────────────
    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%' || echo '50'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (notifRoot.brightDragging) return
                let v = parseInt(text.trim())
                if (!isNaN(v)) notifRoot.brightnessLevel = v / 100.0
            }
        }
    }

    // ── Actions ───────────────────────────────────────────
    function setVolume(val) {
        let c = Math.max(0, Math.min(1.5, val))
        notifRoot.volumeLevel = c
        Quickshell.execDetached(["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + c.toFixed(2)])
    }

    function setBrightness(val) {
        let p = Math.round(Math.max(1, Math.min(100, val * 100)))
        notifRoot.brightnessLevel = p / 100.0
        Quickshell.execDetached(["sh", "-c", "brightnessctl set " + p + "% -q"])
    }

    function toggleMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        Qt.callLater(() => { volProc.running = true })
    }

    function toggleDnd() {
        Quickshell.execDetached(["swaync-client", "--toggle-dnd"])
        Qt.callLater(() => { dndProc.running = true })
    }

    function refreshAll() {
        countProc.running  = true
        dndProc.running    = true
        volProc.running    = true
        brightProc.running = true
    }

    Timer {
        interval: 2000
        running: Globals.notificationsOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: refreshAll()
    }

    // ── UI ────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Theme.surface
        border.color: Theme.borderColor
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // ── Header ────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        text: "Notifications"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 26
                        font.weight: Font.Black
                    }
                    Text {
                        text: notifRoot.notifCount === 0
                            ? "You're all caught up"
                            : notifRoot.notifCount + " notification" + (notifRoot.notifCount === 1 ? "" : "s")
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                }

                // DND pill
                Rectangle {
                    height: 32
                    implicitWidth: dndRow.implicitWidth + 24
                    radius: 16
                    color: notifRoot.dndEnabled
                        ? Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.22)
                        : Theme.overlay
                    border.color: notifRoot.dndEnabled ? Theme.mauve : Theme.borderColor
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        id: dndRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: notifRoot.dndEnabled ? "󰂛" : "󰂚"
                            color: notifRoot.dndEnabled ? Theme.mauve : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Text {
                            text: "DND"
                            color: notifRoot.dndEnabled ? Theme.mauve : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notifRoot.toggleDnd()
                    }
                }
            }

            // ── Sliders card ──────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: slidersCol.implicitHeight + 32
                radius: 16
                color: Theme.overlay
                border.color: Theme.borderColor
                border.width: 1

                ColumnLayout {
                    id: slidersCol
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 18; rightMargin: 18
                    }
                    spacing: 18

                    // ── Volume ────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: muteMa.containsMouse
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: notifRoot.volumeMuted ? "󰝟"
                                    : notifRoot.volumeLevel > 0.66 ? "󰕾"
                                    : notifRoot.volumeLevel > 0.33 ? "󰖀" : "󰕿"
                                color: notifRoot.volumeMuted ? Theme.red : Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 17
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            MouseArea {
                                id: muteMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: notifRoot.toggleMute()
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 32

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 5; radius: 3
                                color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.25)

                                Rectangle {
                                    width: Math.min(parent.width, (notifRoot.volumeLevel / 1.5) * parent.width)
                                    height: parent.height; radius: parent.radius
                                    color: notifRoot.volumeMuted ? Theme.muted : Theme.accent
                                    Behavior on width { NumberAnimation { duration: 60 } }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                // 100% tick mark
                                Rectangle {
                                    x: parent.width * (1.0 / 1.5) - width / 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 1.5; height: 10; radius: 1
                                    color: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.35)
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(parent.width - width, (notifRoot.volumeLevel / 1.5) * parent.width - width / 2))
                                width: volMa.pressed ? 18 : 14
                                height: volMa.pressed ? 18 : 14
                                radius: width / 2
                                color: Theme.accent
                                border.color: Qt.rgba(1,1,1,0.2); border.width: 1
                                Behavior on width  { NumberAnimation { duration: 80 } }
                                Behavior on height { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: volMa
                                anchors.fill: parent
                                cursorShape: Qt.SizeHorCursor
                                preventStealing: true
                                onPressed:  (e) => { notifRoot.volDragging = true;  notifRoot.setVolume((e.x / width) * 1.5) }
                                onReleased:      { notifRoot.volDragging = false; volProc.running = true }
                                onPositionChanged: (e) => { if (pressed) notifRoot.setVolume((e.x / width) * 1.5) }
                            }
                        }

                        Text {
                            text: Math.round(notifRoot.volumeLevel * 100) + "%"
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 12; font.weight: Font.Bold
                            Layout.minimumWidth: 38
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // ── Brightness ────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Item {
                            width: 32; height: 32
                            Text {
                                anchors.centerIn: parent
                                text: notifRoot.brightnessLevel > 0.66 ? "󰃠"
                                    : notifRoot.brightnessLevel > 0.33 ? "󰃟" : "󰃞"
                                color: Theme.yellow
                                font.family: Theme.fontFamily
                                font.pixelSize: 17
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 32

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 5; radius: 3
                                color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.25)
                                Rectangle {
                                    width: notifRoot.brightnessLevel * parent.width
                                    height: parent.height; radius: parent.radius
                                    color: Theme.yellow
                                    Behavior on width { NumberAnimation { duration: 60 } }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(parent.width - width, notifRoot.brightnessLevel * parent.width - width / 2))
                                width: brightMa.pressed ? 18 : 14
                                height: brightMa.pressed ? 18 : 14
                                radius: width / 2
                                color: Theme.yellow
                                border.color: Qt.rgba(1,1,1,0.2); border.width: 1
                                Behavior on width  { NumberAnimation { duration: 80 } }
                                Behavior on height { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: brightMa
                                anchors.fill: parent
                                cursorShape: Qt.SizeHorCursor
                                preventStealing: true
                                onPressed:  (e) => { notifRoot.brightDragging = true;  notifRoot.setBrightness(e.x / width) }
                                onReleased:      { notifRoot.brightDragging = false; brightProc.running = true }
                                onPositionChanged: (e) => { if (pressed) notifRoot.setBrightness(e.x / width) }
                            }
                        }

                        Text {
                            text: Math.round(notifRoot.brightnessLevel * 100) + "%"
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 12; font.weight: Font.Bold
                            Layout.minimumWidth: 38
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // ── Notification count card ───────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 90
                radius: 16
                color: Theme.overlay
                border.color: Theme.borderColor
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    Rectangle {
                        width: 52; height: 52; radius: 26
                        color: notifRoot.notifCount > 0
                            ? Qt.rgba(Theme.peach.r, Theme.peach.g, Theme.peach.b, 0.15)
                            : Qt.rgba(Theme.muted.r,  Theme.muted.g,  Theme.muted.b,  0.1)
                        border.color: notifRoot.notifCount > 0 ? Theme.peach : Theme.borderColor
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 250 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰂚"
                            color: notifRoot.notifCount > 0 ? Theme.peach : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 24
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: notifRoot.notifCount > 0
                                ? notifRoot.notifCount + " pending"
                                : "Inbox zero"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.weight: Font.Black
                        }
                        Text {
                            text: notifRoot.notifCount > 0
                                ? "Open the panel to review"
                                : "No unread notifications"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    // Clear all
                    Rectangle {
                        width: 38; height: 38; radius: 19
                        visible: notifRoot.notifCount > 0
                        color: clrMa.containsMouse
                            ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.18)
                            : Theme.surface
                        border.color: clrMa.containsMouse ? Theme.red : Theme.borderColor
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            color: clrMa.containsMouse ? Theme.red : Theme.muted
                            font.family: Theme.fontFamily; font.pixelSize: 16
                            Behavior on color { ColorAnimation { duration: 130 } }
                        }
                        MouseArea {
                            id: clrMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["swaync-client", "--close-all"])
                                Qt.callLater(() => { countProc.running = true })
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ── Bottom actions ────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true; height: 48; radius: 12
                    color: panelMa.containsMouse
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                        : Theme.overlay
                    border.color: panelMa.containsMouse ? Theme.accent : Theme.borderColor
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.centerIn: parent; spacing: 10
                        Text { text: "󰵙"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 16 }
                        Text { text: "Open Panel"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold }
                    }
                    MouseArea {
                        id: panelMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Globals.notificationsOpen = false
                            Quickshell.execDetached(["swaync-client", "--open-panel"])
                        }
                        onPressed: parent.scale = 0.95
                        onReleased: parent.scale = 1.0
                    }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 48; radius: 12
                    color: notifRoot.dndEnabled
                        ? Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.18)
                        : Theme.overlay
                    border.color: notifRoot.dndEnabled ? Theme.mauve : Theme.borderColor
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        anchors.centerIn: parent; spacing: 10
                        Text {
                            text: notifRoot.dndEnabled ? "󰂛" : "󰂚"
                            color: notifRoot.dndEnabled ? Theme.mauve : Theme.muted
                            font.family: Theme.fontFamily; font.pixelSize: 16
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Text {
                            text: notifRoot.dndEnabled ? "DND On" : "DND Off"
                            color: notifRoot.dndEnabled ? Theme.mauve : Theme.muted
                            font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: notifRoot.toggleDnd()
                        onPressed: parent.scale = 0.95
                        onReleased: parent.scale = 1.0
                    }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                }
            }
        }
    }
}
