import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../"

Rectangle {
    id: weatherRoot
    radius: 28
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.1)
    border.width: 1
    clip: true

    // ── WEATHER STATE ──
    property string wTemp: "--"
    property string wCondition: "Fetching..."
    property string wWind: "--"
    property string wHumidity: "--"
    property string wLocation: "Unknown"

    // ── SMART ICON MAPPING ENGINE ──
    function getWeatherIcon(condition) {
        let c = condition.toLowerCase()
        if (c.includes("clear") || c.includes("sunny")) return { icon: "󰖙", color: Theme.yellow }
        if (c.includes("partly")) return { icon: "󰖕", color: Theme.peach }
        if (c.includes("cloud") || c.includes("overcast")) return { icon: "󰖐", color: Theme.subtext }
        if (c.includes("rain") || c.includes("drizzle") || c.includes("shower")) return { icon: "󰖗", color: Theme.blue }
        if (c.includes("storm") || c.includes("thunder")) return { icon: "󰖓", color: Theme.mauve }
        if (c.includes("snow") || c.includes("ice")) return { icon: "󰖘", color: Theme.text }
        if (c.includes("fog") || c.includes("mist") || c.includes("smoke")) return { icon: "󰖑", color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6) }
        return { icon: "󰖐", color: Theme.accent } // Fallback
    }

    // ── BACKGROUND NETWORK PARSER ──
    Process {
        id: weatherPoller
        command: ["sh", "-c", "curl -s -m 5 'wttr.in/?format=%t|%C|%w|%h|%l' || echo '--|Offline|--|--|Network Error'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let data = text.trim().split("|")
                if (data.length >= 5) {
                    weatherRoot.wTemp = data[0].replace("+", "") 
                    weatherRoot.wCondition = data[1]
                    weatherRoot.wWind = data[2]
                    weatherRoot.wHumidity = data[3]
                    weatherRoot.wLocation = data[4]
                }
            }
        }
    }

    Timer {
        interval: 1800000 // 30 mins
        running: Globals.controlCenterOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherPoller.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── TOP: HERO SECTION (Like the screenshot) ──
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 24

            // Huge Weather Icon
            Text {
                Layout.alignment: Qt.AlignVCenter
                text: weatherRoot.getWeatherIcon(weatherRoot.wCondition).icon
                color: weatherRoot.getWeatherIcon(weatherRoot.wCondition).color
                font.pixelSize: 84
                
                // Subtle breathing animation for a living UI feel
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.7; to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.7; duration: 2500; easing.type: Easing.InOutSine }
                }
            }

            // Temperature & Condition Text
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: -6

                Text {
                    text: weatherRoot.wTemp
                    color: Theme.text
                    font.family: "Inter"
                    font.pixelSize: 56
                    font.weight: Font.Light // Premium modern thin font
                    font.letterSpacing: -2
                }
                
                Text {
                    text: weatherRoot.wCondition
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.maximumWidth: 180
                }
            }

            Item { Layout.fillWidth: true } // Pushes content to the left
        }

        // ── BOTTOM: STRUCTURED DETAILS STRIP ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: 20
            color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.4)
            border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.1)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 0

                // 1. Location Block
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { 
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰍎" 
                        color: Theme.accent 
                        font.pixelSize: 18 
                    }
                    Text { 
                        Layout.alignment: Qt.AlignHCenter
                        text: weatherRoot.wLocation
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        Layout.maximumWidth: 80
                    }
                }

                // Divider
                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                }

                // 2. Wind Block
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { 
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰖝" 
                        color: Theme.teal 
                        font.pixelSize: 18 
                    }
                    Text { 
                        Layout.alignment: Qt.AlignHCenter
                        text: weatherRoot.wWind
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }

                // Divider
                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                }

                // 3. Humidity Block
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { 
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰖙" 
                        color: Theme.blue 
                        font.pixelSize: 18 
                    }
                    Text { 
                        Layout.alignment: Qt.AlignHCenter
                        text: weatherRoot.wHumidity
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}