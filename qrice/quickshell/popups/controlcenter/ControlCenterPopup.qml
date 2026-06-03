import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "components"
import "../../"

Item {
    id: ccRoot
    
    // Premium right-side dashboard bounds (Taller, slightly narrower for a sidebar feel)
    implicitWidth: 460
    implicitHeight: 850

    // Master Navigation State (Reduced to 2 Tabs)
    property int activeTabIndex: 0
    property var tabNames: ["Dashboard", "System"]

    // ── GLOBAL GLASSMORPHISM BACKGROUND ──
    Rectangle {
        id: bgLayer
        anchors.fill: parent
        radius: 28 // Smoother, Material You style radius
        clip: true
        
        // Deep macOS/Noctalia style layered translucency
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.75)
        border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.2)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 24

            // ── TOP NAVIGATION BAR (Premium Segmented Control) ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: height / 2
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
                border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.15)
                border.width: 1

                // Sliding Active Pill Indicator
                Rectangle {
                    height: parent.height - 8
                    width: (parent.width - 8) / 2
                    y: 4
                    x: 4 + (ccRoot.activeTabIndex * width)
                    radius: height / 2
                    color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.8)
                    
                    Behavior on x { 
                        SpringAnimation { spring: 3.5; damping: 0.7; mass: 1.0 } 
                    }
                }

                // Tab Text & Click Areas
                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: ccRoot.tabNames
                        delegate: Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: ccRoot.activeTabIndex === index ? Theme.text : Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                font.weight: ccRoot.activeTabIndex === index ? Font.Bold : Font.Medium
                                font.letterSpacing: 0.3
                                
                                Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ccRoot.activeTabIndex = index
                            }
                        }
                    }
                }
            }

            // ── MAIN PAGE STACK ──
            StackLayout {
                id: pageStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: ccRoot.activeTabIndex

                // ==========================================
                // PAGE 0: DASHBOARD (User -> Toggles -> Sliders -> Notifications)
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    opacity: StackLayout.isCurrentItem ? 1 : 0
                    scale: StackLayout.isCurrentItem ? 1 : 0.96
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { spring: 4.0; damping: 0.8 } }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 16

                        UserCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 130
                        }

                        QuickToggles {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 300
                        }

                        Sliders {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 200
                        }

                        // Notifications Container
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 20
                            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
                            border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.1)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                Text {
                                    text: "Notifications"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }

                                // Notifications Scroll Area (Hook your backend model here)
                                ScrollView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                                    Text {
                                        anchors.centerIn: parent
                                        text: "No new notifications"
                                        color: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.5)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // PAGE 1: SYSTEM (Weather -> Media -> Performance -> Power)
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    opacity: StackLayout.isCurrentItem ? 1 : 0
                    scale: StackLayout.isCurrentItem ? 1 : 0.96
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { spring: 4.0; damping: 0.8 } }

                    ScrollView {
                        anchors.fill: parent
                        contentWidth: availableWidth
                        clip: true
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: parent.width
                            spacing: 16
                            // Add a bottom margin so the last item doesn't clip the rounded corners
                            anchors.bottomMargin: 16 

                            WeatherCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 250
                            }

                            MediaCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 240
                            }

                            SysMonCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 290
                            }

                            PowerCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 150
                            }
                        }
                    }
                }
            }
        }
    }
}