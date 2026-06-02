import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../"

Item {
    id: wsRoot
    anchors.fill: parent

    property int activeWs: 1
    property var occupiedWs: []

    // ── HYPRLAND IPC READERS ──
    // Fetch active workspace ID
    Process {
        id: procActiveWs
        command: ["sh", "-c", "hyprctl activeworkspace -j | grep -o '\"id\": [0-9]*' | awk '{print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let id = parseInt(text.trim())
                if (!isNaN(id)) wsRoot.activeWs = id
            }
        }
    }

    // Fetch occupied workspace array
    Process {
        id: procOccupiedWs
        command: ["sh", "-c", "hyprctl workspaces -j | grep -o '\"id\": [0-9]*' | awk '{print $2}' | tr '\n' ','"]
        stdout: StdioCollector {
            onStreamFinished: {
                let clean = text.trim().replace(/,$/, "")
                if (clean.length > 0) {
                    wsRoot.occupiedWs = clean.split(",").map(Number)
                } else {
                    wsRoot.occupiedWs = []
                }
            }
        }
    }

    // Single trigger action to switch workspace
    Process {
        id: procSwitchWs
        property int targetWs: 1
        command: ["hyprctl", "dispatch", "workspace", targetWs.toString()]
    }

    // Polling trigger when control center opens or updates
    Timer {
        interval: 1000
        running: Globals.controlCenterOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            procActiveWs.running = true
            procOccupiedWs.running = true
        }
    }

    // ── MAIN LAYOUT ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // Header Section
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text { text: "󰨇"; color: Theme.accent; font.pixelSize: 22 }
            ColumnLayout {
                spacing: 2
                Text { text: "Virtual Desktops"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.Bold }
                Text { text: "Workspace Matrix"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
        }

        // 2x5 Desktop Matrix Grid
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 5
            columnSpacing: 12
            rowSpacing: 12

            Repeater {
                model: 10 // Workspaces 1 through 10

                Rectangle {
                    id: wsTile
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    
                    // State detection flags
                    property int wsId: modelData + 1
                    property bool isActive: wsRoot.activeWs === wsId
                    property bool isOccupied: wsRoot.occupiedWs.includes(wsId)

                    // Dynamic styling based on hardware state
                    color: isActive ? Theme.accent : (isOccupied ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.6) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2))
                    border.color: isActive ? Theme.accent : (isOccupied ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2) : Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.1))
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    // Display text / icon inside card
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: wsTile.wsId.toString()
                            color: wsTile.isActive ? Theme.base : (wsTile.isOccupied ? Theme.text : Theme.subtext)
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.weight: wsTile.isActive ? Font.Black : Font.Bold
                        }

                        // Status Dot indicator inside the matrix node
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 6; height: 6; radius: 3
                            color: wsTile.isActive ? Theme.base : Theme.accent
                            visible: wsTile.isActive || wsTile.isOccupied
                            opacity: wsTile.isActive ? 1.0 : 0.6
                        }
                    }

                    // Click Actions to jump desktops
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onEntered: wsTile.scale = 1.04
                        onExited: wsTile.scale = 1.0
                        
                        onClicked: {
                            procSwitchWs.targetWs = wsTile.wsId
                            procSwitchWs.running = true
                            wsRoot.activeWs = wsTile.wsId // Immediate visual response
                        }
                    }

                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}