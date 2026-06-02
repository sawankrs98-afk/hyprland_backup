import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../"

Rectangle {
    id: powerCardRoot
    radius: 20
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ── INLINE REUSABLE POWER BUTTON COMPONENT ──
        component PowerBtn: Rectangle {
            id: btnRoot
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            
            property string icon: ""
            property string label: ""
            property color accentColor: Theme.accent
            property var actionCmd: function(){}

            // Dynamic color states based on hover
            color: pwrMouse.containsMouse 
                   ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) 
                   : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                   
            border.color: pwrMouse.containsMouse 
                          ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.5) 
                          : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.0)
            border.width: 1

            // macOS style hover bounce
            scale: pwrMouse.containsMouse ? (pwrMouse.pressed ? 0.92 : 1.05) : 1.0

            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: btnRoot.icon
                    color: pwrMouse.containsMouse ? btnRoot.accentColor : Theme.text
                    font.pixelSize: 24
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: btnRoot.label
                    color: pwrMouse.containsMouse ? Theme.text : Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            MouseArea {
                id: pwrMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    Globals.controlCenterOpen = false // Close the popup before executing
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
            accentColor: Theme.mauve
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