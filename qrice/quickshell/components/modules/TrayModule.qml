import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../"

Rectangle {
    id: root
    
    // ── Perfectly matches your other bar pills ──
    height: 30
    radius: 15
    color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.88)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.22)
    border.width: 1
    
    // Auto-expands based on how many apps are running
    implicitWidth: mainLayout.implicitWidth + 24
    clip: true

    RowLayout {
        id: mainLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 10

        // ── 1. The System Tray (App Icons) ──
        Row {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
            
            Repeater {
                model: SystemTray.items
                delegate: Item {
                    width: 20; height: 20
                    
                    Image {
                        anchors.fill: parent
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        sourceSize.width: 20
                        sourceSize.height: 20
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        // Satisfying hover & click pop
                        scale: containsMouse ? (pressed ? 0.90 : 1.15) : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                        // Native app interaction
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                modelData.activate()
                            } else if (mouse.button === Qt.RightButton) {
                                // This triggers the app's native right-click menu!
                                modelData.contextMenu() 
                            } else if (mouse.button === Qt.MiddleButton) {
                                modelData.secondaryActivate()
                            }
                        }
                    }
                }
            }
        }

        // ── 2. Subtle Separator (Hides if no apps are open) ──
        Rectangle {
            width: 1
            height: 14
            color: Theme.muted
            opacity: 0.3
            visible: SystemTray.items.length > 0
        }

        
    }
}