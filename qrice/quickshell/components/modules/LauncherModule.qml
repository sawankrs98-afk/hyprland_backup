import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"

Item {
    id: root
    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

    implicitWidth: 38
    implicitHeight: 38

    Text {
        anchors.centerIn: parent
        text: "󰣇"
        color: launchMa.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.75)
        font.family: Theme.fontFamily
        font.pixelSize: 25

        scale: launchMa.pressed ? 0.82 : 1.0

        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on color  { ColorAnimation  { duration: 130 } }
    }

    MouseArea {
        id: launchMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                Quickshell.execDetached(["fuzzel"])
            else if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["wlogout"])
        }
    }
}
