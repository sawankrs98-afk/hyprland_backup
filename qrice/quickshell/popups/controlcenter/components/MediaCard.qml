import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import "../../../"

Rectangle {
    id: mediaRoot
    radius: 20
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
    border.width: 1
    clip: true // Critical for keeping the blurred background contained

    // Helper to format track seconds into m:ss
    function formatTime(microseconds) {
        if (isNaN(microseconds) || microseconds <= 0) return "0:00"
        let secs = Math.floor(microseconds / 1000000)
        let m = Math.floor(secs / 60)
        let s = Math.floor(secs % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    // ── NATIVE MPRIS ENGINE ──
    property var currentPlayer: {
        let dummy = Mpris.players.length
        let players = Mpris.players.values || []
        
        let active = null
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].isPlaying) {
                active = players[i]
                break
            }
        }
        
        if (active) return active
        if (players.length > 0) return players[0]
        return null
    }

    Timer {
        interval: 1000
        running: mediaRoot.currentPlayer !== null && mediaRoot.currentPlayer.isPlaying
        repeat: true
        onTriggered: mediaRoot.currentPlayer.positionChanged()
    }

    // ── 1. BLURRED CARD BACKGROUND ──
    Image {
        id: bgArt
        anchors.fill: parent
        source: mediaRoot.currentPlayer && mediaRoot.currentPlayer.trackArtUrl ? mediaRoot.currentPlayer.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        visible: false 
        asynchronous: true
    }

    MultiEffect {
        source: bgArt
        anchors.fill: bgArt
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        saturation: 1.2
        opacity: mediaRoot.currentPlayer ? 0.4 : 0.0
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    }

    // Dark gradient overlay for text legibility
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.5) }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.9) }
        }
    }

    // ── 2. HORIZONTAL CARD CONTENT ──
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        opacity: mediaRoot.currentPlayer ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 500 } }

        // ── LEFT: CRISP ALBUM ART ──
        Rectangle {
            width: 140
            height: 140
            radius: 16
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.6)
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
            border.width: 1
            clip: true
            Layout.alignment: Qt.AlignVCenter

            // Drop shadow illusion
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 1.0
                shadowOpacity: 0.5
                shadowColor: "#000000"
                shadowVerticalOffset: 4
            }

            Image {
                anchors.fill: parent
                source: mediaRoot.currentPlayer?.trackArtUrl || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: mediaRoot.currentPlayer !== null && mediaRoot.currentPlayer.trackArtUrl !== ""
            }

            // Idle Icon
            Text {
                anchors.centerIn: parent
                text: "󰎆"
                color: Theme.accent
                font.pixelSize: 48
                opacity: 0.5
                visible: !mediaRoot.currentPlayer || !mediaRoot.currentPlayer.trackArtUrl
            }
        }

        // ── RIGHT: METADATA & CONTROLS ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Source Indicator
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                
                Text {
                    text: {
                        let name = (mediaRoot.currentPlayer?.identity || "").toLowerCase()
                        if (name.includes("spotify")) return ""
                        if (name.includes("firefox") || name.includes("chromium") || name.includes("zen")) return ""
                        return "󰎆"
                    }
                    color: {
                        let name = (mediaRoot.currentPlayer?.identity || "").toLowerCase()
                        if (name.includes("spotify")) return Theme.green
                        return Theme.accent
                    }
                    font.pixelSize: 13
                }
                Text {
                    Layout.fillWidth: true
                    text: mediaRoot.currentPlayer?.identity || "System Media"
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                }
            }

            Item { height: 8 }

            // Track Text
            Text {
                Layout.fillWidth: true
                text: mediaRoot.currentPlayer?.trackTitle || "No Track Selected"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 20
                font.weight: Font.Black
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: mediaRoot.currentPlayer?.trackArtist || "Unknown Artist"
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            // Progress Bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                        width: parent.width * (mediaRoot.currentPlayer && mediaRoot.currentPlayer.length > 0 ? (mediaRoot.currentPlayer.position / mediaRoot.currentPlayer.length) : 0)
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.Linear } }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: mediaRoot.currentPlayer ? mediaRoot.formatTime(mediaRoot.currentPlayer.position) : "0:00"
                        color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: mediaRoot.currentPlayer ? mediaRoot.formatTime(mediaRoot.currentPlayer.length) : "0:00"
                        color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Medium
                    }
                }
            }

            Item { height: 8 }

            // Playback Controls
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Text {
                    text: "󰒟"; color: Theme.subtext; font.pixelSize: 16
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mediaRoot.currentPlayer?.shuffle() }
                }
                
                Item { Layout.fillWidth: true }

                Text {
                    text: "󰒮"; color: Theme.text; font.pixelSize: 24
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        scale: pressed ? 0.8 : 1.0; Behavior on scale { NumberAnimation { duration: 100 } }
                        onClicked: mediaRoot.currentPlayer?.previous() 
                    }
                }

                Rectangle {
                    width: 44; height: 44; radius: 22
                    color: Theme.accent
                    
                    Text {
                        anchors.centerIn: parent
                        text: mediaRoot.currentPlayer && mediaRoot.currentPlayer.isPlaying ? "󰏤" : "󰐊"
                        color: Theme.base
                        font.pixelSize: 20
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        scale: pressed ? 0.9 : 1.0; Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        onClicked: mediaRoot.currentPlayer?.togglePlaying()
                    }
                }

                Text {
                    text: "󰒭"; color: Theme.text; font.pixelSize: 24
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        scale: pressed ? 0.8 : 1.0; Behavior on scale { NumberAnimation { duration: 100 } }
                        onClicked: mediaRoot.currentPlayer?.next() 
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "󰑖"; color: Theme.subtext; font.pixelSize: 16
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mediaRoot.currentPlayer?.loop() }
                }
            }
        }
    }

    // ── IDLE FALLBACK ──
    Text {
        anchors.centerIn: parent
        text: "System Idle"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 14
        visible: !mediaRoot.currentPlayer
    }
}