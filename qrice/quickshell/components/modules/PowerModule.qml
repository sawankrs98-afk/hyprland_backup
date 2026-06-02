import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"

Item {
    id: root
    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

    implicitWidth: 38
    implicitHeight: 38

    Text {
        anchors.centerIn: parent
        text: "⏻"
        color: powerMa.containsMouse
            ? Theme.red
            : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.6)
        font.family: Theme.fontFamily
        font.pixelSize: 18

        scale: powerMa.pressed ? 0.82 : 1.0

        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on color  { ColorAnimation  { duration: 130 } }
    }

    MouseArea {
        id: powerMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: Quickshell.execDetached(["wlogout"])
    }
}
