import QtQuick
import QtQuick.Effects
import "../../"
import "../../popups/wifi"
import "../../popups/bluetooth"
import "../../popups/battery"
import "../../popups/volume"
import "../../popups/calendar"
import "../../popups/brightness"
import "../../popups/notifications"
import "../../popups/system"
import "../../popups/media"
import "../../popups/controlcenter"

Rectangle {
    id: popupRoot
    radius: 22
    color: Qt.rgba(
        Theme.surface.r,
        Theme.surface.g,
        Theme.surface.b,
        0.92
    )
    border.width: 1
    border.color: Qt.rgba(
        Theme.borderColor.r,
        Theme.borderColor.g,
        Theme.borderColor.b,
        0.45
    )
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 1.0
        shadowOpacity: 0.35
        shadowVerticalOffset: 8
        shadowHorizontalOffset: 0
    }
    opacity: 0
    scale: 0.92
    y: -16
    transformOrigin: Item.Top

    Component.onCompleted: {
        popupAnim.restart()
    }

    ParallelAnimation {
        id: popupAnim
        NumberAnimation { target: popupRoot; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: popupRoot; property: "scale";   from: 0.92; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: popupRoot; property: "y";       from: -16; to: 0; duration: 240; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
    }

    Loader {
    anchors.fill: parent
    sourceComponent: {
        if (Globals.wifiOpen)          return wifiComp
        if (Globals.bluetoothOpen)     return btComp
        if (Globals.batteryOpen)       return batComp
        if (Globals.volumeOpen)        return volComp
        if (Globals.calendarOpen)      return calComp
        if (Globals.brightnessOpen)    return brightComp
        if (Globals.notificationsOpen) return notifComp
        if (Globals.sysmonOpen)        return sysmonComp
        if (Globals.mediaOpen)         return mediaComp
        if (Globals.controlCenterOpen) return ccComp
        return null
    }
}

    Component { id: wifiComp;   WifiPopup        { anchors.fill: parent } }
    Component { id: btComp;     BluetoothPopup   { anchors.fill: parent } }
    Component { id: batComp;    BatteryPopup     { anchors.fill: parent } }
    Component { id: volComp;    VolumePopup      { anchors.fill: parent } }
    Component { id: calComp;    CalendarPopup    { anchors.fill: parent } }
    Component { id: brightComp; BrightnessPopup  { anchors.fill: parent } }
    Component { id: notifComp;  NotificationPopup { anchors.fill: parent } }
    Component { id: ccComp; ControlCenterPopup { anchors.fill: parent } }
    Component { id: sysmonComp; SystemMonitorPopup { anchors.fill: parent } }
    Component { id: mediaComp; MediaPopup { anchors.fill: parent } }
}