import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../"
import "workspaces"
import "modules"

Item {
    id: barRoot
    anchors.fill: parent

    // ── Inline components ─────────────────────────────────

    component BarDivider: Rectangle {
        width: 1
        height: 16
        color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.22)
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 4
        Layout.rightMargin: 4
    }

    // Shared pill bubble used for grouped modules
    component ModulePill: Rectangle {
        id: pillRoot
        default property alias content: pillLayout.data
        property color glowColor: Theme.accent
        
        // Native click handling so we don't break the layout
        property bool clickable: false
        signal clicked()

        implicitHeight: 30
        implicitWidth:  pillLayout.implicitWidth + 24 // Added slight padding
        radius: height / 2

        color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.55)
        border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.20)
        border.width: 1

        // Hover glow layer
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(
                pillRoot.glowColor.r,
                pillRoot.glowColor.g,
                pillRoot.glowColor.b,
                pillHover.hovered ? 0.07 : 0.0
            )
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        scale: pillHover.hovered ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        HoverHandler { id: pillHover }

        // VISIBLE property ensures it doesn't steal clicks when clickable is false
        MouseArea {
            anchors.fill: parent
            visible: pillRoot.clickable 
            cursorShape: Qt.PointingHandCursor
            onClicked: pillRoot.clicked()
        }

        RowLayout {
            id: pillLayout
            anchors.centerIn: parent
            spacing: 10
        }
    }

    // ── Bar surface ───────────────────────────────────────
    Rectangle {
        id: barSurface
        anchors.fill: parent
        // Fixed: Restored to Theme.base for the normal dark background, kept solid
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 1.0) 

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height: 1
            color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.20)
        }

        // ══════════════════════════════════════════════════
        // CENTER: Clock (Rendered first so sides can anchor)
        // ══════════════════════════════════════════════════
        Item {
            id: centerClock
            anchors.centerIn:       parent
            implicitWidth:          clockRow.implicitWidth + 24
            implicitHeight:         32

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: clockMa.containsMouse
                    ? Qt.rgba(1, 1, 1, 0.05)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            scale: clockMa.pressed ? 0.96 : 1.0
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: 7

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: clockTimer.timeText
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
                    color: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.5)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: clockTimer.dateText
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    color: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.75)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            QtObject {
                id: clockTimer
                property string timeText: ""
                property string dateText: ""

                Component.onCompleted: update()

                function update() {
                    let now = new Date()
                    timeText = now.toLocaleTimeString([], {
                        hour: "numeric", minute: "2-digit", hour12: true
                    })
                    dateText = now.toLocaleDateString([], {
                        month: "numeric", day: "2-digit", year: "2-digit"
                    })
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clockTimer.update()
            }

            MouseArea {
                id: clockMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Globals.wifiOpen          = false
                    Globals.bluetoothOpen     = false
                    Globals.batteryOpen       = false
                    Globals.notificationsOpen = false
                    Globals.controlCenterOpen = false
                    Globals.calendarOpen      = !Globals.calendarOpen
                }
            }
        }

        // ══════════════════════════════════════════════════
        // LEFT: Logo + Workspaces + Window Title Bubble
        // ══════════════════════════════════════════════════
        RowLayout {
            anchors.left:           parent.left
            anchors.right:          centerClock.left // Prevents overlap with clock
            anchors.leftMargin:     20
            anchors.rightMargin:    16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8 

            Item {
                implicitWidth: 32; implicitHeight: 32
                Text {
                    anchors.centerIn: parent
                    text: "✦"
                    color: "#ffffff"
                    font.family: Theme.fontFamily
                    font.pixelSize: 25
                }
            }



            Workspaces {
                Layout.alignment: Qt.AlignVCenter
            }



            // Window title perfectly matches the Media bubble styling
            ModulePill {
                glowColor: Theme.mauve
                WindowTitleModule {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.maximumWidth: 300 
                    clip: true
                }
            }
            
            Item { Layout.fillWidth: true } 
        }

        // ══════════════════════════════════════════════════
        // RIGHT: Media | Tray | Notif | Battery | [WiFi+BT]
        // ══════════════════════════════════════════════════
        RowLayout {
            anchors.right:          parent.right
            anchors.left:           centerClock.right // Prevents overlap with clock
            anchors.rightMargin:    20
            anchors.leftMargin:     16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            Item { Layout.fillWidth: true } 

            ModulePill {
                glowColor: Theme.mauve
                visible: mediaModInner.hasMedia
                MediaModule {
                    id: mediaModInner
                }
            }

                        BarDivider {}

            TrayModule {
                Layout.alignment: Qt.AlignVCenter
            }

                        BarDivider {}

            Item {
                implicitWidth: 30; implicitHeight: 30
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 30; height: 30; radius: 15
                    color: Qt.rgba(
                        Theme.peach.r, Theme.peach.g, Theme.peach.b,
                        notifHover.hovered ? 0.10 : 0.0
                    )
                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    color: notifHover.hovered ? Theme.peach : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                scale: notifMa.pressed ? 0.88 : 1.0
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                HoverHandler { id: notifHover }

                MouseArea {
                    id: notifMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Globals.notificationsOpen = !Globals.notificationsOpen
                        Globals.wifiOpen          = false
                        Globals.bluetoothOpen     = false
                        Globals.batteryOpen       = false
                        Globals.calendarOpen      = false
                        Globals.controlCenterOpen = false
                    }
                }
            }

            BatteryModule {
                Layout.alignment: Qt.AlignVCenter
            }
            
            ModulePill {
                id: wifiBtPill
                glowColor: Theme.sky
                
                clickable: true
                onClicked: {
                    Globals.controlCenterOpen = !Globals.controlCenterOpen
                    Globals.wifiOpen          = false
                    Globals.bluetoothOpen     = false
                    Globals.batteryOpen       = false
                    Globals.notificationsOpen = false
                    Globals.calendarOpen      = false
                }

                Item {
                    implicitWidth: 22; implicitHeight: 22

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (!wifiModRef.connected) return "󰖪"
                            let s = parseInt(wifiModRef.signal)
                            if (s >= 80) return "󰖩"
                            if (s >= 60) return "󰤥"
                            if (s >= 40) return "󰤢"
                            if (s >= 20) return "󰤟"
                            return "󰤯"
                        }
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }

                    WifiModule {
                        id: wifiModRef
                        visible: false
                        enabled: false 
                    }
                }


                Item {
                    implicitWidth: 22; implicitHeight: 22

                    Text {
                        anchors.centerIn: parent
                        text: !btModRef.powered ? "󰂲" : btModRef.connected ? "󰂱" : "󰂯"
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                    }

                    BluetoothModule {
                        id: btModRef
                        visible: false
                        enabled: false
                    }
                }
            }
        }
    }
}