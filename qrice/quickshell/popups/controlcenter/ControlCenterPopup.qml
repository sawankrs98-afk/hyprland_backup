import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "components"
import "../../"

Item {
    id: ccRoot
    
    // Premium desktop dashboard bounds
    implicitWidth: 560
    implicitHeight: 780

    // Master Navigation State (Now exactly 3 Tabs)
    property int activeTabIndex: 0
    property var tabNames: ["Dashboard", "Performance", "System"]

    // ── GLOBAL GLASSMORPHISM BACKGROUND ──
    Rectangle {
        id: bgLayer
        anchors.fill: parent
        radius: 24
        clip: true
        
        // Deep macOS/Noctalia style layered translucency
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.65)
        border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.2)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 24

            // ── TOP NAVIGATION BAR ──
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 44

                // Tab Buttons
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
                                color: ccRoot.activeTabIndex === index ? Theme.accent : Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.weight: ccRoot.activeTabIndex === index ? Font.Bold : Font.Medium
                                font.letterSpacing: 0.5
                                
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

                // Smooth Sliding Active Indicator
                Rectangle {
                    id: activeIndicator
                    height: 3
                    radius: 1.5
                    color: Theme.accent
                    y: parent.height - height
                    
                    // Math-driven width and position for 3 tabs
                    width: parent.width / 3
                    x: ccRoot.activeTabIndex * width
                    
                    Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                }

                // Subtle separator line
                Rectangle {
                    width: parent.width
                    height: 1
                    y: parent.height - 1
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    z: -1
                }
            }

            // ── MAIN PAGE STACK ──
            StackLayout {
                id: pageStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: ccRoot.activeTabIndex

                // ==========================================
                // PAGE 0: DASHBOARD
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    opacity: StackLayout.isCurrentItem ? 1 : 0
                    scale: StackLayout.isCurrentItem ? 1 : 0.96
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 16

                        UserCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 110
                        }

                        QuickToggles {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 280
                        }

                        Sliders {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }

                // ==========================================
                // PAGE 1: PERFORMANCE
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    opacity: StackLayout.isCurrentItem ? 1 : 0
                    scale: StackLayout.isCurrentItem ? 1 : 0.96
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                    SysMonCard {
                        anchors.fill: parent
                    }
                }

                // ==========================================
                // PAGE 2: SYSTEM (Integrated View)
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    opacity: StackLayout.isCurrentItem ? 1 : 0
                    scale: StackLayout.isCurrentItem ? 1 : 0.96
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                    ScrollView {
                        anchors.fill: parent
                        contentWidth: availableWidth
                        clip: true
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: parent.width
                            spacing: 16

                            // 1. WEATHER (Top)
                            WeatherCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 150
                            }

                            // 2. MEDIA (Centerpiece)
                            MediaCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 240
                            }

                            // 3. POWER ACTIONS (Bottom)
                            PowerCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 170
                            }

                            
                        }
                    }
                }
            }
        }
    }
}