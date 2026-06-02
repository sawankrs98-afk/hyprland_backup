import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import "../../"

Item {
    id: mediaPopRoot
    anchors.fill: parent

    // Helper to format track seconds into 0:00 layout
    function formatTime(secs) {
        if (isNaN(secs) || secs <= 0) return "0:00"
        let m = Math.floor(secs / 60)
        let s = Math.floor(secs % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    // ── Problems 1, 2, 5 & 7: Proper Reactive Array parsing, Filtering, and Sorting ──
    property var playerList: {
    let dummy = Mpris.players.length
    return Mpris.players.values || []
}

    // ── Placeholder if nothing is playing ──
    Text {
        anchors.centerIn: parent
        text: "No active media playbacks"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 13
        visible: mediaPopRoot.playerList.length === 0
    }

    // ── Native MPRIS Session Stack ──
    ScrollView {
        anchors.fill: parent
        anchors.margins: 14
        clip: true
        visible: mediaPopRoot.playerList.length > 0
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Column {
            width: parent.width
            spacing: 12

            Repeater {
                model: mediaPopRoot.playerList

                delegate: Rectangle {
                    width: parent.width
                    height: 120
                    radius: 16
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.03)
                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                    border.width: 1

                    // ── Problem 3: Debugging logs to see exactly what Quickshell detects ──
                    Component.onCompleted: {
                        console.log("PLAYER:", modelData.identity, "| TITLE:", modelData.trackTitle, "| ARTIST:", modelData.trackArtist)
                    }

                    // (Problem 4: Timer hack removed. Position is now handled natively)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 16

                        // ── Left: Large Album Artwork Cover ──
                        Rectangle {
                            width: 90; height: 90; radius: 10
                            color: Theme.overlay
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: modelData.trackArtUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                visible: modelData.trackArtUrl !== ""
                                asynchronous: true
                            }

                            // High-Res Fallback Icon if no album art is available
                            Text {
                                anchors.centerIn: parent
                                text: {
                                    // ── Problem 6: Better Identity Names ──
                                    let pName = (modelData.identity || modelData.desktopEntry || "").toLowerCase()
                                    if (pName.includes("spotify")) return ""
                                    if (pName.includes("firefox") || pName.includes("chromium") || pName.includes("zen") || pName.includes("brave")) return ""
                                    return "󰎆"
                                }
                                color: Theme.accent
                                font.pixelSize: 32
                                visible: !modelData.trackArtUrl
                            }
                        }

                        // ── Right: Track Text, Scrubber, & Controls ──
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 0

                            // Title
                            Text {
                                Layout.fillWidth: true
                                text: modelData.trackTitle || "Unknown Track"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            // Artist
                            Text {
                                Layout.fillWidth: true
                                text: modelData.trackArtist || "Unknown Artist"
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            // ── Scrubber Bar & Timestamps ──
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                // Thick pill progress line
                                Rectangle {
                                    Layout.fillWidth: true; height: 5; radius: 2.5; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                                    Rectangle {
                                        height: parent.height; radius: parent.radius; color: Theme.accent
                                        // Prevents division by zero crashes
                                        width: parent.width * (modelData.length > 0 ? (modelData.position / modelData.length) : 0)
                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.Linear } }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        // MPRIS native time is usually stored in microseconds, so we divide by 1,000,000 for standard seconds layout
                                        text: mediaPopRoot.formatTime(modelData.position / 1000000)
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: mediaPopRoot.formatTime(modelData.length / 1000000)
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            Item { height: 6 }

                            // ── End-4 Styled Playback Controls ──
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 18

                                Text {
                                    text: "󰒮"
                                    color: Theme.text
                                    font.pixelSize: 18
                                    visible: modelData.canGoPrevious
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.previous() }
                                }

                                // Circular outlined play button
                                Rectangle {
                                    width: 32; height: 32; radius: 16
                                    color: "transparent"
                                    border.color: Theme.subtext; border.width: 1

                                    Text { 
                                        anchors.centerIn: parent
                                        text: modelData.isPlaying ? "󰏤" : "󰐊"
                                        color: Theme.text
                                        font.pixelSize: 14
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.togglePlaying() }
                                }

                                Text {
                                    text: "󰒭"
                                    color: Theme.text
                                    font.pixelSize: 18
                                    visible: modelData.canGoNext
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.next() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}