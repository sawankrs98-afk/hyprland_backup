import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../"

Rectangle {
    id: root

    color: Theme.surface
    radius: 16
    border.color: Theme.borderColor
    border.width: 1

    // --- 1. STATE MANAGEMENT ---
    property date today: new Date()
    property date selectedDate: today
    
    // Controls what month is currently visible on the grid
    property int displayMonth: selectedDate.getMonth()
    property int displayYear: selectedDate.getFullYear()

    // Fixed real-world constants
    property int realDay: today.getDate()
    property int realMonth: today.getMonth()
    property int realYear: today.getFullYear()

    property int cellSize: 42

    // --- 2. MOCK DATA MODELS ---
    // In a final rice, these would be populated by Quickshell.Process reading from your system
    ListModel {
        id: eventModel
        ListElement { year: 2026; month: 4; day: 15; title: "Data Structures Exam"; time: "10:00 AM"; type: "urgent" }
        ListElement { year: 2026; month: 4; day: 15; title: "Lab Assignment Due"; time: "11:59 PM"; type: "task" }
        ListElement { year: 2026; month: 4; day: 22; title: "Meet with Professor"; time: "2:00 PM"; type: "meeting" }
        ListElement { year: 2026; month: 5; day: 6; title: "Vande Bharat to Katra"; time: "6:00 AM"; type: "travel" }
    }

    // --- 3. HELPER FUNCTIONS ---
    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    function firstDayOffset(year, month) {
        let d = new Date(year, month, 1)
        let day = d.getDay()
        return day === 0 ? 6 : day - 1
    }

    function nextMonth() {
        if (displayMonth === 11) {
            displayMonth = 0
            displayYear++
        } else {
            displayMonth++
        }
    }

    function previousMonth() {
        if (displayMonth === 0) {
            displayMonth = 11
            displayYear--
        } else {
            displayMonth--
        }
    }
    
    function resetToToday() {
        selectedDate = today
        displayMonth = realMonth
        displayYear = realYear
    }

    // Check if a specific cell has events (for the indicator dot)
    function hasEvents(d, m, y) {
        for (let i = 0; i < eventModel.count; i++) {
            let ev = eventModel.get(i)
            if (ev.day === d && ev.month === m && ev.year === y) return true
        }
        return false
    }

    // --- 4. GESTURE CONTROLS ---
    MouseArea {
        anchors.fill: parent
        property real startX: 0
        onPressed: startX = mouse.x
        onReleased: {
            let delta = mouse.x - startX
            if (delta > 80) root.previousMonth()
            else if (delta < -80) root.nextMonth()
        }
    }

    WheelHandler {
        onWheel: function(event) {
            if (event.angleDelta.y > 0) root.previousMonth()
            else root.nextMonth()
        }
    }

    // --- 5. MAIN LAYOUT ---
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ==========================================
        // LEFT PANEL: CALENDAR GRID & CONTROLS
        // ==========================================
        ColumnLayout {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            spacing: 16

            // Header: Month/Year & Navigation
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDate(new Date(root.displayYear, root.displayMonth, 1), "MMMM yyyy")
                    color: Theme.text
                    font.family: Theme.fontFamily; font.pixelSize: 22; font.weight: Font.Bold
                }

                Rectangle {
                    width: 32; height: 32; radius: 8; color: Theme.overlay
                    Text { anchors.centerIn: parent; text: "󰃭"; color: Theme.text; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: root.resetToToday() }
                }
                
                Rectangle {
                    width: 32; height: 32; radius: 8; color: Theme.overlay
                    Text { anchors.centerIn: parent; text: "◀"; color: Theme.text; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: root.previousMonth() }
                }

                Rectangle {
                    width: 32; height: 32; radius: 8; color: Theme.overlay
                    Text { anchors.centerIn: parent; text: "▶"; color: Theme.text; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: root.nextMonth() }
                }
            }

            // Calendar Container
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, 0.4)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Weekday Header
                    Row {
                        spacing: 0
                        Repeater {
                            model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                            Text {
                                width: root.cellSize; horizontalAlignment: Text.AlignHCenter
                                text: modelData; color: Theme.subtext
                                font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold
                            }
                        }
                    }

                    // Calendar Grid
                    Grid {
                        columns: 7; rowSpacing: 4; columnSpacing: 0
                        Repeater {
                            model: 42
                            Rectangle {
                                required property int index
                                width: root.cellSize; height: root.cellSize
                                radius: 8

                                property int offset: root.firstDayOffset(root.displayYear, root.displayMonth)
                                property int day: index - offset + 1
                                property bool valid: day >= 1 && day <= root.daysInMonth(root.displayYear, root.displayMonth)
                                
                                property bool isToday: valid && day === root.realDay && root.displayMonth === root.realMonth && root.displayYear === root.realYear
                                property bool isSelected: valid && day === root.selectedDate.getDate() && root.displayMonth === root.selectedDate.getMonth() && root.displayYear === root.selectedDate.getFullYear()

                                // Visual states
                                color: isSelected ? Theme.peach : (isToday ? Qt.rgba(Theme.peach.r, Theme.peach.g, Theme.peach.b, 0.2) : "transparent")
                                border.color: isToday && !isSelected ? Theme.peach : "transparent"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.valid ? parent.day : ""
                                    color: parent.isSelected ? Theme.base : (parent.isToday ? Theme.peach : Theme.text)
                                    font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: parent.isSelected ? Font.Bold : Font.Medium
                                }

                                // Event Indicator Dot
                                Rectangle {
                                    visible: parent.valid && root.hasEvents(parent.day, root.displayMonth, root.displayYear)
                                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 4 }
                                    width: 4; height: 4; radius: 2
                                    color: parent.isSelected ? Theme.base : Theme.accent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: parent.color = parent.isSelected ? Theme.peach : Theme.overlay
                                    onExited: parent.color = parent.isSelected ? Theme.peach : (parent.isToday ? Qt.rgba(Theme.peach.r, Theme.peach.g, Theme.peach.b, 0.2) : "transparent")
                                    onClicked: {
                                        if (parent.valid) {
                                            root.selectedDate = new Date(root.displayYear, root.displayMonth, parent.day)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillHeight: true; width: 1; color: Theme.borderColor
        }

        // ==========================================
        // RIGHT PANEL: DYNAMIC DAY VIEW & FOCUS
        // ==========================================
        ColumnLayout {
            Layout.preferredWidth: 240
            Layout.fillHeight: true
            spacing: 16

            // Dynamic Header based on selectedDate
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                Text { 
                    text: Qt.formatDate(root.selectedDate, "dddd")
                    color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 16 
                }
                Text { 
                    text: Qt.formatDate(root.selectedDate, "MMMM d, yyyy")
                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 22; font.weight: Font.Bold 
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderColor; opacity: 0.5 }

            // Schedule/Events List
            Text { text: "SCHEDULE"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
            
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                
                ColumnLayout {
                    width: parent.width; spacing: 8
                    
                    // Filter the model to only show events for the selectedDate
                    Repeater {
                        model: eventModel
                        delegate: Rectangle {
                            visible: model.day === root.selectedDate.getDate() && model.month === root.selectedDate.getMonth() && model.year === root.selectedDate.getFullYear()
                            Layout.fillWidth: true; height: visible ? 56 : 0; radius: 8
                            color: Theme.overlay
                            border.width: 1
                            border.color: model.type === "urgent" ? Theme.red : (model.type === "meeting" ? Theme.blue : Theme.accent)
                            
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 10; spacing: 12
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: model.title; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { text: model.time; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11 }
                                }
                            }
                        }
                    }

                    // Empty State if no events
                    Item {
                        Layout.fillWidth: true; height: 100
                        visible: !root.hasEvents(root.selectedDate.getDate(), root.selectedDate.getMonth(), root.selectedDate.getFullYear())
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 8
                            Text { text: "󰃭"; color: Theme.muted; font.pixelSize: 24; Layout.alignment: Qt.AlignHCenter }
                            Text { text: "No events planned."; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                }
            }

            // Focus/Pomodoro Timer Module (Bottom Right)
            Rectangle {
                Layout.fillWidth: true; height: 90; radius: 12
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                border.color: Theme.accent; border.width: 1
                
                property int timeLeft: 1500 // 25 mins in seconds
                property bool timerRunning: false

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 4
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "FOCUS TIMER"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 24; height: 24; radius: 12; color: Theme.accent
                            Text { anchors.centerIn: parent; text: parent.parent.parent.timerRunning ? "󰏤" : "󰐊"; color: Theme.base; font.pixelSize: 12 }
                            MouseArea { 
                                anchors.fill: parent 
                                onClicked: parent.parent.parent.timerRunning = !parent.parent.parent.timerRunning 
                            }
                        }
                    }
                    
                    Text { 
                        text: Math.floor(parent.parent.timeLeft / 60).toString().padStart(2, '0') + ":" + (parent.parent.timeLeft % 60).toString().padStart(2, '0')
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 32; font.weight: Font.Black 
                    }
                }

                Timer {
                    interval: 1000; running: parent.timerRunning; repeat: true
                    onTriggered: {
                        if (parent.timeLeft > 0) parent.timeLeft--
                        else parent.timerRunning = false
                    }
                }
            }
        }
    }
}