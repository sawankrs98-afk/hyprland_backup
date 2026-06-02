import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../"

Rectangle {
    id: togglesCard
    radius: 20
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
    border.width: 1

    // ── LOCAL STATE FOR TOGGLES NOT IN GLOBALS ──
    property bool isNightLightOn: false
    property bool isDarkModeOn: true 
    property bool isAirplaneOn: false

    GridLayout {
        anchors.fill: parent
        anchors.margins: 18
        columns: 3
        rowSpacing: 14
        columnSpacing: 14

        // ── INLINE REUSABLE TOGGLE COMPONENT ──
        component CCToggle: Rectangle {
            id: toggleRoot // Explicit ID for safe property bindings
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            
            // Required properties
            property string icon: ""
            property string label: ""
            property bool isActive: false
            property color activeColor: Theme.accent
            property var action: function(){}

            // Background & Border States
            color: isActive ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.18) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
            border.color: isActive ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.6) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
            border.width: 1

            // ── FIXED ANIMATION ENGINE ──
            // Scale and Behavior are declared directly on the root component
            scale: toggleMouse.containsMouse ? (toggleMouse.pressed ? 0.94 : 1.04) : 1.0
            
            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

            // Inner Content
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Text { 
                    Layout.alignment: Qt.AlignHCenter
                    text: toggleRoot.icon
                    color: toggleRoot.isActive ? toggleRoot.activeColor : Theme.text
                    font.pixelSize: 24
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                
                Text { 
                    Layout.alignment: Qt.AlignHCenter
                    text: toggleRoot.label
                    color: toggleRoot.isActive ? Theme.text : Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }

            // Interaction Engine
            MouseArea {
                id: toggleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: toggleRoot.action()
            }
        }

        // ── TOP ROW ──

        CCToggle {
            icon: "󰤨"
            label: "Wi-Fi"
            isActive: Globals.isWifiOn
            activeColor: Theme.accent
            action: function() { 
                Globals.isWifiOn = !Globals.isWifiOn
                Quickshell.execDetached(["nmcli", "radio", "wifi", Globals.isWifiOn ? "on" : "off"]) 
            }
        }

        CCToggle {
            icon: "󰂯"
            label: "Bluetooth"
            isActive: Globals.isBluetoothOn
            activeColor: Theme.blue
            action: function() { 
                Globals.isBluetoothOn = !Globals.isBluetoothOn
                Quickshell.execDetached(["bluetoothctl", "power", Globals.isBluetoothOn ? "on" : "off"]) 
            }
        }

        CCToggle {
            icon: !Globals.notificationsOpen ? "󰂛" : "󰂚"
            label: "DND"
            isActive: !Globals.notificationsOpen 
            activeColor: Theme.peach
            action: function() { 
                Globals.notificationsOpen = !Globals.notificationsOpen
                Quickshell.execDetached(["swaync-client", "-t"]) 
            }
        }

        // ── BOTTOM ROW ──

        CCToggle {
            icon: "󰈐"
            label: "Night Light"
            isActive: togglesCard.isNightLightOn
            activeColor: Theme.yellow
            action: function() { 
                togglesCard.isNightLightOn = !togglesCard.isNightLightOn
                if (togglesCard.isNightLightOn) {
                    Quickshell.execDetached(["wlsunset", "-t", "4500"])
                } else {
                    Quickshell.execDetached(["killall", "wlsunset"])
                }
            }
        }

        CCToggle {
            icon: "󰔎"
            label: "Dark Mode"
            isActive: togglesCard.isDarkModeOn
            activeColor: Theme.mauve
            action: function() { 
                togglesCard.isDarkModeOn = !togglesCard.isDarkModeOn
            }
        }

        CCToggle {
            icon: "󰀝"
            label: "Airplane"
            isActive: togglesCard.isAirplaneOn
            activeColor: Theme.red
            action: function() { 
                togglesCard.isAirplaneOn = !togglesCard.isAirplaneOn
                if (togglesCard.isAirplaneOn) {
                    Quickshell.execDetached(["nmcli", "radio", "all", "off"])
                    Globals.isWifiOn = false
                    Globals.isBluetoothOn = false
                } else {
                    Quickshell.execDetached(["nmcli", "radio", "all", "on"])
                    Globals.isWifiOn = true
                    Globals.isBluetoothOn = true
                }
            }
        }
    }
}