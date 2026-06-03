import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../"

Rectangle {
    id: powerCardRoot
    radius: 28 // Matched to global Control Center style
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.1)
    border.width: 1
    clip: true

    RowLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // ── INLINE REUSABLE POWER BUTTON (Premium Squircle) ──
        component PowerBtn: Rectangle {
            id: btnRoot
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 20 // Soft inner squircle shape
            
            property string icon: ""
            property string label: ""
            property color accentColor: Theme.accent
            property var actionCmd: function(){}

            // Dynamic color states
            color: pwrMouse.containsMouse 
                   ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) 
                   : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                   
            border.color: pwrMouse.containsMouse 
                          ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) 
                          : "transparent"
            border.width: 1

            // Bouncy spring animation for interactions
            scale: pwrMouse.pressed ? 0.9 : (pwrMouse.containsMouse ? 1.05 : 1.0)

            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 250 } }
            Behavior on scale { SpringAnimation { spring: 5.0; damping: 0.6 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: btnRoot.icon
                    color: pwrMouse.containsMouse ? btnRoot.accentColor : Theme.text
                    font.pixelSize: 26
                    Behavior on color { ColorAnimation { duration: 250 } }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: btnRoot.label
                    color: pwrMouse.containsMouse ? Theme.text : Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }

            MouseArea {
                id: pwrMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    Globals.controlCenterOpen = false 
                    btnRoot.actionCmd()
                }
            }
        }

        // ── ACTION MAPPING ──

        PowerBtn {
            icon: "󰌾"
            label: "Lock"
            accentColor: Theme.peach
            actionCmd: function() { Quickshell.execDetached(["loginctl", "lock-session"]) }
        }

        PowerBtn {
            icon: "󰒲"
            label: "Suspend"
            accentColor: Theme.blue
            actionCmd: function() { Quickshell.execDetached(["systemctl", "suspend"]) }
        }

        PowerBtn {
            icon: "󰍃"
            label: "Logout"
            accentColor: Theme.mauve // Reverted to mauve, as it shouldn't render black here since it's mixed with opacity
            actionCmd: function() { Quickshell.execDetached(["pkill", "Hyprland"]) }
        }

        PowerBtn {
            icon: "󰜉"
            label: "Reboot"
            accentColor: Theme.teal
            actionCmd: function() { Quickshell.execDetached(["systemctl", "reboot"]) }
        }

        PowerBtn {
            icon: "󰐥"
            label: "Shutdown"
            accentColor: Theme.red
            actionCmd: function() { Quickshell.execDetached(["systemctl", "poweroff"]) }
        }
    }
}