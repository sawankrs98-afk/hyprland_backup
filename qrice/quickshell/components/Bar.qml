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

    // ── INLINE COMPONENTS ─────────────────────────────────
    
    // 1. Subtle dividing line
    component BarDivider: Rectangle {
        width: 1
        height: 16
        color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.22)
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 6
        Layout.rightMargin: 6
    }

    // 2. Passive hover wrapper (Allows clicks to pass through to native modules)
    component GlowWrapper: Item {
        id: wrapper
        property color glowColor: Theme.accent
        property Item targetModule: null
        
        implicitWidth: targetModule ? targetModule.implicitWidth : 0
        implicitHeight: targetModule ? targetModule.implicitHeight : 0
        
        Rectangle {
            anchors.centerIn: parent
            width: wrapper.implicitWidth + 16
            height: wrapper.implicitHeight + 8
            radius: 8
            color: hoverTracker.hovered ? Qt.rgba(glowColor.r, glowColor.g, glowColor.b, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        
        scale: hoverTracker.hovered ? 1.03 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        
        HoverHandler { id: hoverTracker }
    }

    // ── BAR SURFACE ───────────────────────────────────────
    Rectangle {
        id: barSurface
        anchors.fill: parent
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.95)

        // Bottom boundary line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.25)
        }

        // ══════════════════════════════════════════════════
        // LEFT: Identity, Workspaces & Window Title
        // ══════════════════════════════════════════════════
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // 1. Fedora / Shell Logo (Clicks Swallowed)
            Item {
                implicitWidth: 36
                implicitHeight: 36
                
                Text {
                    anchors.centerIn: parent
                    text: "󰣇"
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.9)
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                }
                
                MouseArea { 
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {} 
                }
            }

            BarDivider {}

            // 2. Workspaces (Interactive)
            Workspaces {
                id: workspacesItem
                Layout.alignment: Qt.AlignVCenter
            }

            BarDivider {}

            // 3. Active Window Title (Clicks Swallowed)
            Item {
                implicitWidth: windowTitleMod.implicitWidth
                implicitHeight: windowTitleMod.implicitHeight
                Layout.alignment: Qt.AlignVCenter

                WindowTitleModule {
                    id: windowTitleMod
                    anchors.fill: parent
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.ArrowCursor
                    onClicked: {} 
                }
            }
        }

        // ══════════════════════════════════════════════════
        // CENTER: Clock & Control Center Toggle
        // ══════════════════════════════════════════════════
        Item {
            id: centerAnchor
            anchors.centerIn: parent
            implicitWidth: clockMod.implicitWidth
            implicitHeight: clockMod.implicitHeight
            
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 24
                height: parent.height + 12
                radius: 8
                color: clockMa.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            scale: clockMa.pressed ? 0.95 : (clockMa.containsMouse ? 1.03 : 1.0)
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            
            ClockModule {
                id: clockMod
                anchors.centerIn: parent
            }
            
            MouseArea {
                id: clockMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Globals.wifiOpen = false;
                    Globals.bluetoothOpen = false;
                    Globals.batteryOpen = false;
                    Globals.notificationsOpen = false;
                    Globals.controlCenterOpen = !Globals.controlCenterOpen;
                }
            }
        }

        // ══════════════════════════════════════════════════
        // RIGHT: Media, Tray, Notifications & Status
        // ══════════════════════════════════════════════════
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // 1. Media
            GlowWrapper {
                glowColor: Theme.mauve
                targetModule: mediaMod
                MediaModule { id: mediaMod; anchors.centerIn: parent }
            }

            BarDivider {}

            // 2. System Tray
            TrayModule {
                Layout.alignment: Qt.AlignVCenter
            }

            BarDivider {}

            // 3. Notification Bell (Amber Glow)
            Item {
                implicitWidth: 28
                implicitHeight: 28
                Layout.alignment: Qt.AlignVCenter
                
                Rectangle {
                    id: notifBg
                    anchors.centerIn: parent
                    width: 36
                    height: 36
                    radius: 18
                    color: "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                }
                
                scale: notifMa.pressed ? 0.95 : (notifMa.containsMouse ? 1.03 : 1.0)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                
                MouseArea {
                    id: notifMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onEntered: notifBg.color = Qt.rgba(Theme.peach.r, Theme.peach.g, Theme.peach.b, 0.08)
                    onExited: notifBg.color = "transparent"
                    onClicked: {
                        Globals.wifiOpen = false;
                        Globals.bluetoothOpen = false;
                        Globals.batteryOpen = false;
                        Globals.controlCenterOpen = false;
                        Globals.notificationsOpen = !Globals.notificationsOpen;
                    }
                }
            }

            BarDivider {}

            // 4. Status Module Cluster (UPGRADED SPACING)
            // 4. Status Module Cluster (FIXED NATIVE CLICK TARGETS)
            RowLayout {
                spacing: 14 
                Layout.alignment: Qt.AlignVCenter
                
                // WiFi (Cyan Glow)
                GlowWrapper {
    glowColor: Theme.sky
    targetModule: wifiMod
    Item {
        anchors.fill: parent
        WifiModule { id: wifiMod; anchors.fill: parent }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Globals.wifiOpen = !Globals.wifiOpen
                Globals.batteryOpen = false
                Globals.bluetoothOpen = false
                Globals.notificationsOpen = false
                Globals.controlCenterOpen = false
            }
        }
    }
}

                GlowWrapper {
    glowColor: Theme.green
    targetModule: batMod

    Item {
        anchors.fill: parent
        BatteryModule {
            id: batMod
            anchors.fill: parent
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Globals.batteryOpen = !Globals.batteryOpen
                Globals.wifiOpen = false
                Globals.bluetoothOpen = false
                Globals.notificationsOpen = false
                Globals.controlCenterOpen = false
            }
        }
    }
}

GlowWrapper {
    glowColor: Theme.blue
    targetModule: btMod
    Item {
        anchors.fill: parent
        BluetoothModule { id: btMod; anchors.fill: parent }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Globals.bluetoothOpen = !Globals.bluetoothOpen
                Globals.batteryOpen = false
                Globals.wifiOpen = false
                Globals.notificationsOpen = false
                Globals.controlCenterOpen = false
            }
        }
    }
}


            }
        }
    }
}