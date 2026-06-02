import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../"

Rectangle {
    id: weatherRoot
    radius: 20
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
    border.width: 1

    // ── WEATHER STATE ──
    property string wTemp: "--"
    property string wCondition: "Fetching Weather..."
    property string wWind: "--"
    property string wHumidity: "--"
    property string wLocation: "Unknown Location"

    // ── SMART ICON MAPPING ENGINE ──
    function getWeatherIcon(condition) {
        let c = condition.toLowerCase()
        if (c.includes("clear") || c.includes("sunny")) return { icon: "󰖙", color: Theme.yellow }
        if (c.includes("partly")) return { icon: "󰖕", color: Theme.peach }
        if (c.includes("cloud") || c.includes("overcast")) return { icon: "󰖐", color: Theme.subtext }
        if (c.includes("rain") || c.includes("drizzle") || c.includes("shower")) return { icon: "󰖗", color: Theme.blue }
        if (c.includes("storm") || c.includes("thunder")) return { icon: "󰖓", color: Theme.mauve }
        if (c.includes("snow") || c.includes("ice")) return { icon: "󰖘", color: Theme.text }
        if (c.includes("fog") || c.includes("mist")) return { icon: "󰖑", color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6) }
        return { icon: "󰖐", color: Theme.accent } // Fallback
    }

    // ── BACKGROUND NETWORK PARSER ──
    Process {
        id: weatherPoller
        // format: Temp | Condition | Wind | Humidity | Location
        // -m 5 ensures it doesn't hang the UI if the network drops
        command: ["sh", "-c", "curl -s -m 5 'wttr.in/?format=%t|%C|%w|%h|%l' || echo '--|Offline|--|--|Network Error'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let data = text.trim().split("|")
                if (data.length >= 5) {
                    weatherRoot.wTemp = data[0].replace("+", "") // Clean up the '+' sign
                    weatherRoot.wCondition = data[1]
                    weatherRoot.wWind = data[2]
                    weatherRoot.wHumidity = data[3]
                    weatherRoot.wLocation = data[4]
                }
            }
        }
    }

    // Refresh weather every 30 minutes (1800000 ms)
    Timer {
        interval: 1800000
        running: Globals.controlCenterOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherPoller.running = true
    }

    // ── MASTER LAYOUT ──
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 24

        // ── LEFT: MASSIVE HERO ICON & TEMP ──
        RowLayout {
            spacing: 16
            
            Text {
                text: weatherRoot.getWeatherIcon(weatherRoot.wCondition).icon
                color: weatherRoot.getWeatherIcon(weatherRoot.wCondition).color
                font.pixelSize: 64
                
                // Subtle breathing animation for the icon
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.8; to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.8; duration: 2000; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: weatherRoot.wTemp
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 42
                font.weight: Font.Black
                font.letterSpacing: -2
            }
        }

        // ── DIVIDER ──
        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
        }

        // ── RIGHT: METADATA GRID ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Location Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: "󰍎"; color: Theme.accent; font.pixelSize: 14 }
                Text { 
                    Layout.fillWidth: true
                    text: weatherRoot.wLocation
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
            }

            // Condition Text
            Text {
                Layout.fillWidth: true
                text: weatherRoot.wCondition
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true } // Flex spacer

            // Wind & Humidity Stats Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Wind
                RowLayout {
                    spacing: 4
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: Qt.rgba(Theme.teal.r, Theme.teal.g, Theme.teal.b, 0.15)
                        Text { anchors.centerIn: parent; text: "󰖝"; color: Theme.teal; font.pixelSize: 12 }
                    }
                    Text { 
                        text: weatherRoot.wWind
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold 
                    }
                }

                // Humidity
                RowLayout {
                    spacing: 4
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.15)
                        Text { anchors.centerIn: parent; text: "󰖙"; color: Theme.blue; font.pixelSize: 12 }
                    }
                    Text { 
                        text: weatherRoot.wHumidity
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Bold 
                    }
                }
            }
        }
    }
}