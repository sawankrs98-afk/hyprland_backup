import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import "../../../"

Rectangle {
    id: mediaRoot
    radius: 28 // Matched to the rest of the Control Center
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
    border.width: 1
    clip: true 

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

    // ── 1. PREMIUM BLURRED BACKGROUND ──
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
        blurMax: 80 // Increased for a smoother, creamier blur
        blur: 1.0
        saturation: 1.3 // Slight color boost to make it pop through the dark overlay
        opacity: mediaRoot.currentPlayer ? 0.6 : 0.0
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    }

    // Heavy dark gradient overlay for perfect text legibility
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.55) }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.95) }
        }
    }

    // ── 2. CARD CONTENT ──
    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24
        opacity: mediaRoot.currentPlayer ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 500 } }

        // ── LEFT: CRISP SQUIRCLE ALBUM ART ──
        Item {
            width: 140
            height: 140
            Layout.alignment: Qt.AlignVCenter

            // The visible squircle mask and shadow
            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: 24 // Modern squircle
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.8)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                border.width: 1
                clip: true

                Image {
                    anchors.fill: parent
                    source: mediaRoot.currentPlayer?.trackArtUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: mediaRoot.currentPlayer !== null && mediaRoot.currentPlayer.trackArtUrl !== ""
                }

                // Idle Icon fallback inside the squircle
                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: Theme.accent
                    font.pixelSize: 48
                    opacity: 0.5
                    visible: !mediaRoot.currentPlayer || !mediaRoot.currentPlayer.trackArtUrl
                }
            }

            // Deep drop shadow
            MultiEffect {
                source: artMask
                anchors.fill: artMask
                shadowEnabled: true
                shadowBlur: 1.5
                shadowOpacity: 0.6
                shadowColor: "#000000"
                shadowVerticalOffset: 6
            }
        }

        // ── RIGHT: METADATA & CONTROLS ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Source Indicator (Spotify, Firefox, etc.)
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
                    font.pixelSize: 14
                }
                Text {
                    Layout.fillWidth: true
                    text: mediaRoot.currentPlayer?.identity || "System Media"
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.5
                    elide: Text.ElideRight
                }
            }

            Item { height: 10 }

            // Track Title
            Text {
                Layout.fillWidth: true
                text: mediaRoot.currentPlayer?.trackTitle || "No Track Selected"
                color: Theme.text
                font.family: "Inter"
                font.pixelSize: 24
                font.weight: Font.Black
                font.letterSpacing: -0.5
                elide: Text.ElideRight
            }

            // Artist
            Text {
                Layout.fillWidth: true
                text: mediaRoot.currentPlayer?.trackArtist || "Unknown Artist"
                color: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.8)
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true } // Pushes controls to the bottom

            // Material You Bulky Progress Bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 8 // Bulky track
                    radius: 4
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                    clip: true

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
                        color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: mediaRoot.currentPlayer ? mediaRoot.formatTime(mediaRoot.currentPlayer.length) : "0:00"
                        color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                    }
                }
            }

            Item { height: 6 }

            // Playback Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Text {
                    text: "󰒟"
                    color: Theme.subtext; font.pixelSize: 18
                    MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: mediaRoot.currentPlayer?.shuffle() }
                }
                
                Item { Layout.fillWidth: true }

                Text {
                    text: "󰒮"
                    color: Theme.text; font.pixelSize: 28
                    MouseArea { 
                        anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor
                        scale: pressed ? 0.8 : 1.0; Behavior on scale { NumberAnimation { duration: 100 } }
                        onClicked: mediaRoot.currentPlayer?.previous() 
                    }
                }

                // Massive Play Button
                Rectangle {
                    width: 56; height: 56; radius: 28
                    color: Theme.accent
                    
                    Text {
                        anchors.centerIn: parent
                        text: mediaRoot.currentPlayer && mediaRoot.currentPlayer.isPlaying ? "󰏤" : "󰐊"
                        color: Theme.base
                        font.pixelSize: 28
                        // Slight offset to visually center the play triangle perfectly
                        anchors.horizontalCenterOffset: (mediaRoot.currentPlayer && mediaRoot.currentPlayer.isPlaying) ? 0 : 2
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        scale: pressed ? 0.9 : 1.0; Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        onClicked: mediaRoot.currentPlayer?.togglePlaying()
                    }
                }

                Text {
                    text: "󰒭"
                    color: Theme.text; font.pixelSize: 28
                    MouseArea { 
                        anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor
                        scale: pressed ? 0.8 : 1.0; Behavior on scale { NumberAnimation { duration: 100 } }
                        onClicked: mediaRoot.currentPlayer?.next() 
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "󰑖"
                    color: Theme.subtext; font.pixelSize: 18
                    MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: mediaRoot.currentPlayer?.loop() }
                }
            }
        }
    }

    // ── IDLE FALLBACK ──
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: !mediaRoot.currentPlayer

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰝛"
            color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.5)
            font.pixelSize: 48
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Nothing is playing"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.weight: Font.Medium
        }
    }
}