import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../"

Item {
    id: root

    property int batteryPercent: 100
    property string batteryStatus: "Unknown"
    property string activeProfile: "balanced"

    Process {
        id: batteryProc

        command: [
            "sh",
            "-c",
            "echo $(cat /sys/class/power_supply/BAT*/capacity)';'$(cat /sys/class/power_supply/BAT*/status)"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(";")

                if (parts.length >= 2) {
                    root.batteryPercent = parseInt(parts[0])
                    root.batteryStatus = parts[1]
                }
            }
        }
    }

    Process {
        id: profileProc

        command: ["powerprofilesctl", "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.activeProfile = text.trim()
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            batteryProc.running = true
            profileProc.running = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18

        spacing: 18

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 320

            Rectangle {
                anchors.centerIn: parent

                width: 300
                height: 300

                radius: 150

                color: Qt.rgba(
                    Theme.peach.r,
                    Theme.peach.g,
                    Theme.peach.b,
                    0.05
                )

                border.width: 22
                border.color: Qt.rgba(
                    Theme.peach.r,
                    Theme.peach.g,
                    Theme.peach.b,
                    0.15
                )
            }

            Rectangle {
                anchors.centerIn: parent

                width: 245
                height: 245

                radius: 122

                color: Theme.base

                border.width: 10
                border.color: Theme.peach
            }

            Column {
                anchors.centerIn: parent

                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text:
                        batteryStatus === "Charging"
                        ? "󰂄"
                        : "󰁹"

                    color: Theme.peach

                    font.family: Theme.fontFamily
                    font.pixelSize: 26
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: batteryPercent + "%"

                    color: Theme.text

                    font.family: Theme.fontFamily
                    font.pixelSize: 64
                    font.weight: Font.Black
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: batteryStatus.toUpperCase()

                    color: Theme.subtext

                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 10

            Repeater {
                model: [
                    { icon: "󰌾", cmd: "loginctl lock-session" },
                    { icon: "󰤄", cmd: "systemctl suspend" },
                    { icon: "󰑐", cmd: "systemctl reboot" },
                    { icon: "󰐥", cmd: "systemctl poweroff" }
                ]

                Rectangle {
                    Layout.fillWidth: true
                    height: 72

                    radius: 14

                    color: Theme.overlay

                    border.width: 1
                    border.color: Theme.borderColor

                    Text {
                        anchors.centerIn: parent

                        text: modelData.icon

                        color: Theme.text

                        font.family: Theme.fontFamily
                        font.pixelSize: 26
                    }

                    MouseArea {
                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached([
                                "sh",
                                "-c",
                                modelData.cmd
                            ])
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 10

            Repeater {
                model: [
                    {
                        text: "Perform",
                        icon: "󰓅",
                        profile: "performance"
                    },
                    {
                        text: "Balance",
                        icon: "󰾅",
                        profile: "balanced"
                    },
                    {
                        text: "Saver",
                        icon: "󰌪",
                        profile: "power-saver"
                    }
                ]

                Rectangle {
                    Layout.fillWidth: true
                    height: 52

                    radius: 12

                    color:
                        root.activeProfile === modelData.profile
                        ? Theme.peach
                        : Qt.rgba(
                            Theme.peach.r,
                            Theme.peach.g,
                            Theme.peach.b,
                            0.12
                        )

                    border.width: 1
                    border.color: Theme.borderColor

                    Row {
                        anchors.centerIn: parent

                        spacing: 8

                        Text {
                            text: modelData.icon

                            color:
                                root.activeProfile === modelData.profile
                                ? Theme.base
                                : Theme.peach

                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                        }

                        Text {
                            text: modelData.text

                            color:
                                root.activeProfile === modelData.profile
                                ? Theme.base
                                : Theme.text

                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Quickshell.execDetached([
                                "powerprofilesctl",
                                "set",
                                modelData.profile
                            ])

                            root.activeProfile =
                                modelData.profile
                        }
                    }
                }
            }
        }
    }
}