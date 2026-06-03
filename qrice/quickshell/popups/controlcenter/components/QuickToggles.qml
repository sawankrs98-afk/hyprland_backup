import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../"

Rectangle {
    id: togglesCard
    radius: 28
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.1)
    border.width: 1
    clip: true

    // ── LOCAL STATE FOR TOGGLES NOT IN GLOBALS ──
    property bool isNightLightOn: false
    property bool isDarkModeOn: true 
    property bool isAirplaneOn: false

    GridLayout {
        anchors.fill: parent
        anchors.margins: 18
        columns: 2 
        rowSpacing: 14
        columnSpacing: 14

        // ── INLINE REUSABLE TOGGLE COMPONENT (True Android Style) ──
        component CCToggle: Rectangle {
            id: toggleRoot
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 32 
            
            property string icon: ""
            property string label: ""
            property string sublabel: isActive ? "On" : "Off"
            property bool isActive: false
            
            property color activeColor: Theme.accent
            
            // NEW: Determines if only the icon gets a circular background (Android Wi-Fi style)
            // or if the whole pill fills with color (Android Dark Mode style)
            property bool iconOnlyFill: false 
            
            property bool hasMenu: false
            property var toggleAction: function(){}
            property var menuAction: function(){}

            // Pill Background Color Logic
            color: isActive && !iconOnlyFill
                ? activeColor 
                : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.6)
            
            border.color: isActive && !iconOnlyFill
                ? "transparent" 
                : Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
            border.width: 1

            scale: toggleMouse.pressed || menuMouse.pressed ? 0.95 : 1.0
            Behavior on scale { SpringAnimation { spring: 5.0; damping: 0.6 } }
            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 250 } }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ── LEFT SIDE: MAIN TOGGLE ──
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8  // Reduced margin to fit the circular background
                        anchors.rightMargin: 12
                        spacing: 12

                        // Icon Container (Circular Background)
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 24
                            color: toggleRoot.isActive && toggleRoot.iconOnlyFill ? toggleRoot.activeColor : "transparent"
                            Behavior on color { ColorAnimation { duration: 250 } }

                            Text { 
                                anchors.centerIn: parent
                                text: toggleRoot.icon
                                // If the circle is filled OR the whole pill is filled, icon becomes the dark base color
                                color: toggleRoot.isActive ? Theme.base : Theme.text
                                font.pixelSize: 22
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                        }
                        
                        // Text Stack
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0

                            Text { 
                                text: toggleRoot.label
                                // If whole pill is filled, text becomes dark. Otherwise it stays white/Theme.text
                                color: toggleRoot.isActive && !toggleRoot.iconOnlyFill ? Theme.base : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                font.letterSpacing: 0.3
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                            Text { 
                                text: toggleRoot.sublabel
                                color: toggleRoot.isActive && !toggleRoot.iconOnlyFill 
                                    ? Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.75) 
                                    : Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                        }
                    }

                    MouseArea {
                        id: toggleMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleRoot.toggleAction()
                    }
                }

                // ── RIGHT SIDE: MENU CHEVRON ──
                Item {
                    visible: toggleRoot.hasMenu
                    width: 48
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂" 
                        color: toggleRoot.isActive && !toggleRoot.iconOnlyFill ? Theme.base : Theme.subtext
                        font.pixelSize: 18
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    MouseArea {
                        id: menuMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleRoot.menuAction()
                    }
                }
            }
        }

        // ── TOP ROW ──

        CCToggle {
            icon: "󰤨"
            label: "Wi-Fi"
            // Set to Theme.text to get that pure Android white icon circle
            activeColor: Theme.text 
            isActive: Globals.isWifiOn
            hasMenu: true
            iconOnlyFill: true // <--- Triggers the circle-only fill style
            toggleAction: function() { 
                Globals.isWifiOn = !Globals.isWifiOn
                Quickshell.execDetached(["nmcli", "radio", "wifi", Globals.isWifiOn ? "on" : "off"]) 
            }
            menuAction: function() {
                Globals.wifiOpen = true
            }
        }

        CCToggle {
            icon: "󰂯"
            label: "Bluetooth"
            activeColor: Theme.text 
            isActive: Globals.isBluetoothOn
            hasMenu: true
            iconOnlyFill: true // <--- Triggers the circle-only fill style
            toggleAction: function() { 
                Globals.isBluetoothOn = !Globals.isBluetoothOn
                Quickshell.execDetached(["bluetoothctl", "power", Globals.isBluetoothOn ? "on" : "off"]) 
            }
            menuAction: function() {
                Globals.bluetoothOpen = true
            }
        }

        // ── MIDDLE ROW ──

        CCToggle {
            icon: !Globals.notificationsOpen ? "󰂛" : "󰂚"
            label: "Do Not Disturb"
            activeColor: Theme.peach
            isActive: !Globals.notificationsOpen 
            iconOnlyFill: false // <--- Entire pill gets filled
            toggleAction: function() { 
                Globals.notificationsOpen = !Globals.notificationsOpen
                Quickshell.execDetached(["swaync-client", "-t"]) 
            }
        }

        CCToggle {
            icon: "󰈐"
            label: "Night Light"
            activeColor: Theme.yellow
            isActive: togglesCard.isNightLightOn
            iconOnlyFill: false 
            toggleAction: function() { 
                togglesCard.isNightLightOn = !togglesCard.isNightLightOn
                if (togglesCard.isNightLightOn) {
                    Quickshell.execDetached(["wlsunset", "-t", "4500"])
                } else {
                    Quickshell.execDetached(["killall", "wlsunset"])
                }
            }
        }

        // ── BOTTOM ROW ──

        CCToggle {
            icon: "󰔎"
            label: "Dark Mode"
            activeColor: Theme.text
            isActive: togglesCard.isDarkModeOn
            iconOnlyFill: false 
            toggleAction: function() { 
                togglesCard.isDarkModeOn = !togglesCard.isDarkModeOn
            }
        }

        CCToggle {
            icon: "󰀝"
            label: "Airplane Mode"
            activeColor: Theme.red
            isActive: togglesCard.isAirplaneOn
            iconOnlyFill: false 
            toggleAction: function() { 
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