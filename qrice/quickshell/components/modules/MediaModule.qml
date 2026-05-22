import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    // ── State ─────────────────────────────────────────────
    property string mediaTitle:   ""
    property string mediaArtist:  ""
    property string playerStatus: "Stopped"
    property string mediaArt:     ""
    property real   mediaPosition: 0
    property real   mediaLength:   1

    // Only take up space when something is actually playing
    visible: mediaTitle.length > 0
    implicitWidth:  visible ? mediaPill.implicitWidth : 0
    implicitHeight: 34

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // ── Data process ──────────────────────────────────────
    Process {
        id: mediaProc
        command: [
            "sh", "-c",
            "playerctl metadata --format '{{status}}|{{artist}}|{{title}}|{{mpris:artUrl}}|{{mpris:length}}' 2>/dev/null && echo -n '|' && playerctl position 2>/dev/null || echo ''"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim()
                if (raw === "" || raw === "|") {
                    root.mediaTitle   = ""
                    root.mediaArtist  = ""
                    root.mediaArt     = ""
                    root.playerStatus = "Stopped"
                    root.mediaPosition = 0
                    return
                }
                let p = raw.split("|")
                if (p.length < 5) return
                root.playerStatus = p[0].trim()
                root.mediaArtist  = p[1].trim()
                root.mediaTitle   = p[2].trim()
                let art = p[3].trim()
                root.mediaArt = art.startsWith("file://") ? art : ""
                let len = parseFloat(p[4])
                root.mediaLength = (isNaN(len) || len <= 0) ? 1 : len / 1000000
                if (p.length >= 6) {
                    let pos = parseFloat(p[5])
                    root.mediaPosition = isNaN(pos) ? 0 : pos
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: mediaProc.running = true
    }

    // ── Pill container ────────────────────────────────────
    Rectangle {
        id: mediaPill
        anchors.verticalCenter: parent.verticalCenter

        height: 34
        radius: 10
        clip: true

        // Width = content + padding, capped at 340px
        implicitWidth: Math.min(pillRow.implicitWidth + 24, 340)

        color: mediaMa.containsMouse
            ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 1.0)
            : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.80)

        border.width: 1
        border.color: root.playerStatus === "Playing"
            ? Qt.rgba(Theme.teal.r, Theme.teal.g, Theme.teal.b, 0.55)
            : Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.35)

        Behavior on color       { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
        Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ── Playback progress bar (bottom edge) ───────────
        Rectangle {
            id: progressBar
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.leftMargin:  6
            anchors.rightMargin: 6
            height: 2
            radius: 1
            color:   Theme.teal
            opacity: root.playerStatus === "Playing" ? 0.80 : 0.25

            width: {
                if (root.mediaLength <= 0) return 0
                let ratio = root.mediaPosition / root.mediaLength
                ratio = Math.max(0.0, Math.min(1.0, ratio))
                return ratio * (mediaPill.width - 12)
            }

            Behavior on width {
                NumberAnimation { duration: 1100; easing.type: Easing.Linear }
            }
        }

        // ── Inner row ─────────────────────────────────────
        RowLayout {
            id: pillRow
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin:  12
            anchors.rightMargin: 12
            anchors.bottomMargin: 3   // slight lift so progress bar doesn't clip text
            spacing: 8

            // Album art thumbnail
            Rectangle {
                id: artThumb
                width: 22
                height: 22
                radius: 6
                color: Theme.overlay
                clip: true
                visible: root.mediaArt.length > 0
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.fill: parent
                    source: root.mediaArt
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }

                // Subtle inner border on art
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                }
            }

            // Status dot — glowing teal when playing
            Rectangle {
                width: 7
                height: 7
                radius: 4
                Layout.alignment: Qt.AlignVCenter
                color: root.playerStatus === "Playing" ? Theme.teal : Theme.muted
                opacity: root.playerStatus === "Playing" ? 1.0 : 0.45

                Behavior on color   { ColorAnimation { duration: 220 } }
                Behavior on opacity { NumberAnimation { duration: 220 } }

                // Glow layer
                Rectangle {
                    anchors.centerIn: parent
                    width: 13; height: 13; radius: 7
                    color: "transparent"
                    border.color: Qt.rgba(Theme.teal.r, Theme.teal.g, Theme.teal.b, 0.28)
                    border.width: 1
                    visible: root.playerStatus === "Playing"
                }
            }

            // Artist name
            Text {
                id: artistLabel
                text: root.mediaArtist
                visible: root.mediaArtist.length > 0
                color: Theme.sky
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
                Layout.maximumWidth: 90
            }

            // Separator dot
            Text {
                text: "·"
                visible: root.mediaArtist.length > 0 && root.mediaTitle.length > 0
                color: Theme.muted
                font.pixelSize: 12
                Layout.alignment: Qt.AlignVCenter
            }

            // Title — scrolling marquee if too long
            Item {
                id: titleClip
                Layout.fillWidth: true
                Layout.preferredWidth: Math.min(titleTxt.implicitWidth, 150)
                height: 20
                clip: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: titleTxt
                    text: root.mediaTitle
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter

                    property real animX: 0

                    NumberAnimation on animX {
                        id: scrollAnim
                        from: 0
                        to: -(titleTxt.implicitWidth + 32)
                        duration: Math.max(
                            (titleTxt.implicitWidth / 16) * 1000,
                            3000
                        )
                        loops: Animation.Infinite
                        running: titleTxt.implicitWidth > 150 &&
                                 root.playerStatus === "Playing"
                    }

                    Binding on x {
                        when: scrollAnim.running
                        value: titleTxt.animX
                    }
                }
            }

            // Prev / Next controls — only visible on hover
            RowLayout {
                spacing: 2
                visible: mediaMa.containsMouse
                opacity: mediaMa.containsMouse ? 1.0 : 0.0
                Layout.alignment: Qt.AlignVCenter

                Behavior on opacity { NumberAnimation { duration: 150 } }

                // Previous
                Rectangle {
                    width: 22; height: 22; radius: 11
                    color: prevMa.containsMouse
                        ? Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 1.0)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: prevMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["playerctl", "previous"])
                            mediaProc.running = true
                        }
                    }
                }

                // Next
                Rectangle {
                    width: 22; height: 22; radius: 11
                    color: nextMa.containsMouse
                        ? Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 1.0)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: nextMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["playerctl", "next"])
                            mediaProc.running = true
                        }
                    }
                }
            }
        }

        // ── Click to play/pause ───────────────────────────
        MouseArea {
            id: mediaMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // Only the non-button area triggers play/pause
            onClicked: {
                Quickshell.execDetached(["playerctl", "play-pause"])
                mediaProc.running = true
            }
        }
    }
}