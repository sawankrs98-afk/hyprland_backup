import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../"

RowLayout {
    id: wsRoot
    spacing: 6
    
    Repeater {
        model: [1, 2, 3, 4, 5]
        
        Rectangle {
            width: 26; height: 26; radius: 6
            
            property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
            color: isActive ? Theme.accent : Theme.surface
            
            Text {
                anchors.centerIn: parent
                text: modelData
                color: isActive ? Theme.base : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // THE FIX: Standard terminal execution
                    Quickshell.execDetached(["sh", "-c", "/usr/bin/hyprctl dispatch workspace " + modelData.toString()])
                }
            }
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}
