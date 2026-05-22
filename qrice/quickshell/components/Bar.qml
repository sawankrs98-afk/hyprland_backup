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

    // ── Thin vertical separator for inside the tray pill ──
    component TraySep: Rectangle {
        width: 1
        height: 16
        radius: 1
        Layout.leftMargin: 3
        Layout.rightMargin: 3
        color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.40)
    }

    // ── Full bar background ────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.88)
        border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.22)
        border.width: 1

        // ── Three-column layout ────────────────────────────
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 0

            // ════════════════════════════════════════════════
            // LEFT — launcher + media
            // ════════════════════════════════════════════════
            RowLayout {
                Layout.preferredWidth: barRoot.width * 0.33
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 8

                // Arch launcher button
                Rectangle {
                    id: launcherBtn
                    width: 34
                    height: 30
                    radius: 9

                    property bool hovered: launchMa.containsMouse
                    property bool pressed: launchMa.pressed

                    color: hovered
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                        : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                    border.color: hovered
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.60)
                        : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                    border.width: 1
                    scale: pressed ? 0.86 : (hovered ? 1.06 : 1.0)

                    Behavior on color   { ColorAnimation  { duration: 130 } }
                    Behavior on border.color { ColorAnimation { duration: 130 } }
                    Behavior on scale   { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰣇"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: launchMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["rofi", "-show", "drun"])
                    }
                }

                // Media widget
                MediaModule {}
            }

            // ════════════════════════════════════════════════
            // CENTER — workspace name + dots
            // ════════════════════════════════════════════════
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: 12

                Workspaces {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }
            }

            // ════════════════════════════════════════════════
            // RIGHT — system tray pill
            // ════════════════════════════════════════════════
            Item {
                Layout.preferredWidth: barRoot.width * 0.33
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                height: parent.height

                // The pill — auto-sizes to content
                Rectangle {
                    id: trayPill
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 36
                    radius: 18
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.92)
                    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.32)
                    border.width: 1
                    implicitWidth: trayRow.implicitWidth + 32

                    Behavior on implicitWidth {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        id: trayRow
                        anchors.centerIn: parent
                        spacing: 4

                        WifiModule {}
                        TraySep {}
                        BluetoothModule {}
                        TraySep {}
                        BrightnessModule {}
                        TraySep {}
                        VolumeModule {}
                        TraySep {}
                        BatteryModule {}
                        TraySep {}

                        // Notification bell
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: notifMa.containsMouse
                                ? Qt.rgba(Theme.peach.r, Theme.peach.g, Theme.peach.b, 0.18)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 130 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰂚"
                                color: Theme.peach
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                            }

                            MouseArea {
                                id: notifMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])
                            }
                        }

                        TraySep {}
                        ClockModule {}
                    }
                }
            }

        } // end RowLayout
    } // end background Rectangle
} // end barRoot