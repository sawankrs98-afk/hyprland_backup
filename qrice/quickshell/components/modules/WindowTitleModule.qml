import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Rectangle {
    id: root
    
    height: 30
    radius: 15
    color: "transparent" // Removed the pill background
    border.width: 0      // Removed the border
    
    implicitWidth: mainLayout.implicitWidth + 24

    property string winClass: ""
    property string winTitle: "Desktop"
    property string winIcon: "󱂬"

    function resolveIcon(cls) {
        let c = cls.toLowerCase();
        if (c.includes("brave"))    return "";
        if (c.includes("zen"))      return "󰖟";
        if (c.includes("helium"))   return "󰖟";
        if (c.includes("firefox"))  return "";
        if (c.includes("vesktop"))  return "󰙯";
        if (c.includes("spotify"))  return "";
        if (c.includes("kitty"))    return "";
        if (c.includes("code"))     return "󰨞";
        if (c.includes("telegram")) return "";
        if (c.includes("dolphin"))  return "󰉋";
        if (c.includes("obsidian")) return "󱓧";
        if (c.includes("vlc"))      return "󰕼";
        if (c.includes("zapzap"))   return "";
        
        if (c.length === 0) return "󰇄";
        return "󱂬";
    }

    function resolveAppName(cls) {
        let c = cls.toLowerCase();
        if (c.includes("brave"))    return "Brave";
        if (c.includes("zen"))      return "Zen";
        if (c.includes("helium"))   return "Helium";
        if (c.includes("firefox"))  return "Firefox";
        if (c.includes("vesktop"))  return "Vesktop";
        if (c.includes("spotify"))  return "Spotify";
        if (c.includes("kitty"))    return "Kitty";
        if (c.includes("code"))     return "VS Code";
        if (c.includes("telegram")) return "Telegram";
        if (c.includes("dolphin"))  return "Dolphin";
        if (c.includes("obsidian")) return "Obsidian";
        if (c.includes("vlc"))      return "VLC";
        if (c.includes("zapzap"))   return "ZapZap";
        
        if (c.length === 0) return "Desktop";
        return c.charAt(0).toUpperCase() + c.slice(1);
    }

    Process {
        id: titlePoller
        command: ["sh", "-c", "active=$(hyprctl activewindow); class=$(echo \"$active\" | grep 'class:' | awk '{print $2}'); title=$(echo \"$active\" | grep 'title:' | cut -d' ' -f2-); echo \"$class|$title\""]
        stdout: StdioCollector {
            id: titleCollector
            onStreamFinished: {
                let data = titleCollector.text.trim().split("|")
                if (data.length >= 2 && data[0].length > 0) {
                    root.winClass = data[0].trim()
                    root.winTitle = root.resolveAppName(root.winClass)
                } else {
                    root.winClass = ""
                    root.winTitle = "Desktop"
                }
                root.winIcon = root.resolveIcon(root.winClass)
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: titlePoller.running = true
    }

    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: root.winIcon
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 17
        }

        Text {
            text: root.winTitle
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        scale: containsMouse ? (pressed ? 0.96 : 1.03) : 1.0
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        onClicked: {
            Globals.controlCenterOpen = !Globals.controlCenterOpen
            
            Globals.wifiOpen = false
            Globals.bluetoothOpen = false
            Globals.batteryOpen = false
            Globals.volumeOpen = false
            Globals.calendarOpen = false
            Globals.brightnessOpen = false
            Globals.notificationsOpen = false
            Globals.sysmonOpen = false
            Globals.mediaOpen = false
        }
    }

    Connections {
        target: Globals
        function onWifiOpenChanged()          { if (Globals.wifiOpen)          Globals.controlCenterOpen = false }
        function onBluetoothOpenChanged()     { if (Globals.bluetoothOpen)     Globals.controlCenterOpen = false }
        function onBatteryOpenChanged()       { if (Globals.batteryOpen)       Globals.controlCenterOpen = false }
        function onVolumeOpenChanged()        { if (Globals.volumeOpen)        Globals.controlCenterOpen = false }
        function onCalendarOpenChanged()      { if (Globals.calendarOpen)      Globals.controlCenterOpen = false }
        function onBrightnessOpenChanged()    { if (Globals.brightnessOpen)    Globals.controlCenterOpen = false }
        function onNotificationsOpenChanged() { if (Globals.notificationsOpen) Globals.controlCenterOpen = false }
        function onSysmonOpenChanged()        { if (Globals.sysmonOpen)        Globals.controlCenterOpen = false }
        function onMediaOpenChanged()         { if (Globals.mediaOpen)         Globals.controlCenterOpen = false }
    }
}