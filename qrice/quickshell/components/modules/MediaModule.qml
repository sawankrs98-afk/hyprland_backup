import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../"

Rectangle {
    id: root
    
    height: 30
    radius: 15
    color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.88)
    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.22)
    border.width: 1
    
    implicitWidth: mainLayout.implicitWidth + 24

    // Stable evaluation tracking through proxy maps
    property var currentPlayer: {
        let dummy = Mpris.players.length; 
        let players = Mpris.players.values || [];
        
        // Priority 1: Actively streaming player node
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].isPlaying) {
                return players[i];
            }
        }
        
        // Priority 2: Fallback to first available paused instance
        if (players.length > 0 && players[0]) {
            return players[0];
        }
        
        return null;
    }

    Component.onCompleted: {
        console.log("BAR PLAYER:", root.currentPlayer ? (root.currentPlayer.identity || root.currentPlayer.name) : "NULL")
    }

    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: {
                if (!root.currentPlayer) return "󰝛"
                let name = (root.currentPlayer.identity || root.currentPlayer.name || "").toLowerCase()
                
                if (name.includes("spotify")) return ""
                if (root.currentPlayer.isPlaying) return "󰏤"
                return "󰐊"
            }
            color: Globals.mediaOpen ? Theme.accent : (root.currentPlayer && root.currentPlayer.isPlaying ? Theme.green : Theme.text)
            font.family: Theme.fontFamily
            font.pixelSize: 17
        }

        Text {
            text: {
                if (!root.currentPlayer) return "Music Idle"

                let title = root.currentPlayer.trackTitle || ""
                let artist = root.currentPlayer.trackArtist || ""
                let combined = artist.length > 0 ? title + " • " + artist : title

                return combined.length > 24 ? combined.substring(0, 22) + ".." : combined
            }
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        scale: containsMouse ? (pressed ? 0.94 : 1.04) : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        onClicked: {
            Globals.mediaOpen = !Globals.mediaOpen
            
            Globals.wifiOpen = false
            Globals.bluetoothOpen = false
            Globals.batteryOpen = false
            Globals.volumeOpen = false
            Globals.calendarOpen = false
            Globals.brightnessOpen = false
            Globals.notificationsOpen = false
            Globals.sysmonOpen = false
            Globals.controlCenterOpen = false
        }
    }

    Connections {
        target: Globals
        function onWifiOpenChanged()          { if (Globals.wifiOpen)          Globals.mediaOpen = false }
        function onBluetoothOpenChanged()     { if (Globals.bluetoothOpen)     Globals.mediaOpen = false }
        function onBatteryOpenChanged()       { if (Globals.batteryOpen)       Globals.mediaOpen = false }
        function onVolumeOpenChanged()        { if (Globals.volumeOpen)        Globals.mediaOpen = false }
        function onCalendarOpenChanged()      { if (Globals.calendarOpen)      Globals.mediaOpen = false }
        function onBrightnessOpenChanged()    { if (Globals.brightnessOpen)    Globals.mediaOpen = false }
        function onNotificationsOpenChanged() { if (Globals.notificationsOpen) Globals.mediaOpen = false }
        function onSysmonOpenChanged()        { if (Globals.sysmonOpen)        Globals.mediaOpen = false }
        function onControlCenterOpenChanged() { if (Globals.controlCenterOpen) Globals.mediaOpen = false }
    }
}