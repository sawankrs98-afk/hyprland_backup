import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../../"

Item {
    id: wifiRoot

    // ==========================================
    // SECTION 11: END-4 PROPORTIONS & DIMENSIONS
    // ==========================================
    implicitWidth: 540
    implicitHeight: 740

    // ==========================================
    // STATE PROPERTIES
    // ==========================================
    property string activeSSID: "Not Connected"
    property string activeIP: "Fetching..."
    property string activeFreq: "--"
    property string activeSecurity: "--"
    property string activeBSSID: "--"
    property string activePing: "-- ms"
    property int activeSignal: 0
    property bool isConnected: false

    property var nearbyNetworks: []
    property var savedNetworks: []

    property string targetSSID: ""
    property string targetPassword: ""

    property string downSpeed: "0 KB/s"
    property string upSpeed: "0 KB/s"
    property double lastRx: 0
    property double lastTx: 0
    
    property bool wifiPowered: true
    property bool showSavedNetworks: false
    property bool isScanning: false

    // ==========================================
    // GLOBAL UI ANIMATIONS
    // ==========================================
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    // ==========================================
    // CORE LOGIC FUNCTIONS
    // ==========================================
    function refreshAll() {
        isScanning = true
        activeNetProc.running = true
        nearbyProc.running = true
        savedProc.running = true
        speedProc.running = true
        powerProc.running = true
        pingProc.running = true
    }

    function signalColor(sig) {
        let s = parseInt(sig)
        if (s >= 75) return Theme.green
        if (s >= 50) return Theme.yellow
        if (s >= 25) return Theme.peach
        return Theme.red
    }

    function signalIcon(sig) {
        let s = parseInt(sig)
        if (s >= 80) return "󰤨"
        if (s >= 60) return "󰤥"
        if (s >= 40) return "󰤢"
        if (s >= 20) return "󰤟"
        return "󰤯"
    }

    Component.onCompleted: {
        refreshAll()
    }

    // ==========================================
    // BACKEND DAEMONS (STRICTLY SANITIZED STRINGS)
    // ==========================================

    // Hardware Power State
    Process {
        id: powerProc
        command: ["sh", "-c", "nmcli radio wifi"]
        stdout: StdioCollector {
            onStreamFinished: { 
                wifiRoot.wifiPowered = text.trim().toLowerCase() === "enabled" 
            }
        }
    }

    // Active Network Diagnostics (SSID, Signal, Security, Freq, BSSID, IP)
    Process {
        id: activeNetProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY,FREQ,BSSID dev wifi | grep '^yes:' | head -n1; ip -4 -o addr show dev $(ip route | awk '/default/ {print $5}' | head -n1) 2>/dev/null | awk '{print $4}' | cut -d/ -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                if (lines.length > 0 && lines[0].startsWith("yes:")) {
                    let p = lines[0].split(":")
                    wifiRoot.isConnected = true
                    wifiRoot.activeSSID = p[1] || "Unknown"
                    wifiRoot.activeSignal = parseInt(p[2]) || 0
                    wifiRoot.activeSecurity = p[3] || "Open"
                    wifiRoot.activeFreq = p[4] || "2.4 GHz"
                    // Reconstruct BSSID from remaining colon splits
                    wifiRoot.activeBSSID = p.slice(5).join(":") || "--"
                    
                    if (lines.length > 1) {
                        wifiRoot.activeIP = lines[1]
                    }
                } else {
                    wifiRoot.isConnected = false
                    wifiRoot.activeSSID = "Not Connected"
                    wifiRoot.activeIP = "--"
                    wifiRoot.activeSignal = 0
                    wifiRoot.activeFreq = "--"
                    wifiRoot.activeBSSID = "--"
                    wifiRoot.activeSecurity = "--"
                }
            }
        }
    }

    // Network Ping Telemetry
    Process {
        id: pingProc
        command: ["sh", "-c", "ping -c 1 8.8.8.8 | awk -F'/' 'END{print $5}' || echo '--'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim()
                wifiRoot.activePing = (p.length > 0 && p !== "--") ? Math.round(parseFloat(p)) + " ms" : "-- ms"
            }
        }
    }

    // Saved Profiles Fetcher
    Process {
        id: savedProc
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE connection show | grep '802-11-wireless' | cut -d: -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                let arr = []
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].length > 0 && lines[i] !== wifiRoot.activeSSID) {
                        arr.push({ ssid: lines[i] })
                    }
                }
                wifiRoot.savedNetworks = arr
            }
        }
    }

    // Nearby Networks Scanner & Filter
    Process {
        id: nearbyProc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                let arr = []
                let seen = new Set()

                for (let i = 0; i < lines.length; ++i) {
                    let p = lines[i].split(":")
                    if (p.length < 4 || p[1].length === 0 || p[0].trim() === "*") continue
                    if (seen.has(p[1])) continue
                    
                    seen.add(p[1])
                    arr.push({
                        ssid: p[1],
                        signal: parseInt(p[2]) || 0,
                        secure: p[3].toLowerCase().includes("wpa") || p[3].toLowerCase().includes("wep") || p[3].length > 0
                    })
                }

                // Section 5: Sort Strongest First
                arr.sort((a, b) => b.signal - a.signal)
                wifiRoot.nearbyNetworks = arr
                wifiRoot.isScanning = false
            }
        }
    }

    // Hardware Speed Telemetry
    Process {
        id: speedProc
        command: ["sh", "-c", "iface=$(ip route | awk '/default/ {print $5}' | head -n1); rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0); tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo 0); echo \"$rx:$tx\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim().split(":")
                if (p.length < 2) return
                let rx = parseFloat(p[0])
                let tx = parseFloat(p[1])

                if (wifiRoot.lastRx > 0) {
                    let down = (rx - wifiRoot.lastRx) / 1024
                    wifiRoot.downSpeed = down > 1024 ? (down / 1024).toFixed(1) + " MB/s" : Math.round(down) + " KB/s"
                }
                if (wifiRoot.lastTx > 0) {
                    let up = (tx - wifiRoot.lastTx) / 1024
                    wifiRoot.upSpeed = up > 1024 ? (up / 1024).toFixed(1) + " MB/s" : Math.round(up) + " KB/s"
                }
                wifiRoot.lastRx = rx
                wifiRoot.lastTx = tx
            }
        }
    }

    // Auto-Sync Timer
    Timer {
        interval: 5000
        running: Globals.wifiOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: refreshAll()
    }

    // ==========================================
    // MAIN UI ARCHITECTURE
    // ==========================================
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Theme.surface
        border.color: Theme.borderColor
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // ── SECTION 1: PREMIUM HEADER ──
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { 
                        text: "Network Center"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 26
                        font.weight: Font.Black 
                    }
                    Text { 
                        text: wifiRoot.isConnected ? "Securely connected to routing node" : "Wireless interface offline or disconnected"
                        color: wifiRoot.isConnected ? Theme.muted : Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: 13 
                    }
                }
                
                // Animated Hardware Power Switch
                Rectangle {
                    width: 58
                    height: 32
                    radius: 16
                    color: wifiRoot.wifiPowered ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.2) : Theme.overlay
                    border.color: wifiRoot.wifiPowered ? Theme.blue : Theme.borderColor
                    border.width: 1
                    
                    Behavior on color { ColorAnimation { duration: 250 } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: wifiRoot.wifiPowered ? "ON" : "OFF"
                        color: wifiRoot.wifiPowered ? Theme.blue : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["nmcli", "radio", "wifi", wifiRoot.wifiPowered ? "off" : "on"])
                            refreshAll()
                        }
                    }
                }
            }

            // ── SCROLLVIEW WITH RIGID COLUMN FIX (NO SQUISHING) ──
            ScrollView {
                id: listScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                // Using Column ensures child items maintain their strict Heights
                Column {
                    width: listScroll.width
                    spacing: 16
                    padding: 2

                    // ── SECTION 2: HERO CONNECTED CARD ──
                    Rectangle {
                        width: parent.width - 4
                        height: 250 // Hard boundary guarantees no internal overlap
                        radius: 18
                        color: Theme.overlay
                        border.color: Theme.borderColor
                        border.width: 1
                        visible: wifiRoot.wifiPowered

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                // Status Icon Base
                                Rectangle {
                                    width: 72; height: 72; radius: 36
                                    color: wifiRoot.isConnected ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.1) : Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.1)
                                    border.color: wifiRoot.isConnected ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.3) : "transparent"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: wifiRoot.isConnected ? signalIcon(wifiRoot.activeSignal) : "󰤮"
                                        color: wifiRoot.isConnected ? signalColor(wifiRoot.activeSignal) : Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 42
                                        Behavior on color { ColorAnimation { duration: 250 } }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: wifiRoot.activeSSID
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 22
                                        font.weight: Font.Black
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Dynamic Badge Array (Section 9)
                                    RowLayout {
                                        spacing: 8
                                        Rectangle {
                                            height: 24
                                            implicitWidth: statusTextBadge.implicitWidth + 24
                                            radius: 12
                                            color: wifiRoot.isConnected ? Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.15) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                                            border.color: wifiRoot.isConnected ? Theme.green : Theme.red
                                            border.width: 1
                                            Text { id: statusTextBadge; anchors.centerIn: parent; text: wifiRoot.isConnected ? "Connected" : "Disconnected"; color: wifiRoot.isConnected ? Theme.green : Theme.red; font.pixelSize: 11; font.weight: Font.Bold }
                                        }
                                        Rectangle {
                                            visible: wifiRoot.isConnected
                                            height: 24
                                            implicitWidth: freqTextBadge.implicitWidth + 24
                                            radius: 12
                                            color: Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.15)
                                            border.color: Theme.mauve
                                            border.width: 1
                                            Text { id: freqTextBadge; anchors.centerIn: parent; text: wifiRoot.activeFreq; color: Theme.mauve; font.pixelSize: 11; font.weight: Font.Bold }
                                        }
                                    }
                                }
                            }

                            // Diagnostics Grid
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 16
                                visible: wifiRoot.isConnected
                                Layout.topMargin: 4

                                RowLayout { Layout.fillWidth: true; Text { text: "IP Address:"; color: Theme.subtext; font.pixelSize: 11; font.weight: Font.Bold } Item { Layout.fillWidth: true } Text { text: wifiRoot.activeIP; color: Theme.text; font.pixelSize: 11 } }
                                RowLayout { Layout.fillWidth: true; Text { text: "Signal Level:"; color: Theme.subtext; font.pixelSize: 11; font.weight: Font.Bold } Item { Layout.fillWidth: true } Text { text: wifiRoot.activeSignal + "%"; color: Theme.text; font.pixelSize: 11 } }
                                RowLayout { Layout.fillWidth: true; Text { text: "Security:"; color: Theme.subtext; font.pixelSize: 11; font.weight: Font.Bold } Item { Layout.fillWidth: true } Text { text: wifiRoot.activeSecurity; color: Theme.text; font.pixelSize: 11 } }
                                RowLayout { Layout.fillWidth: true; Text { text: "Latency (Ping):"; color: Theme.subtext; font.pixelSize: 11; font.weight: Font.Bold } Item { Layout.fillWidth: true } Text { text: wifiRoot.activePing; color: Theme.text; font.pixelSize: 11 } }
                            }

                            Item { Layout.fillHeight: true }

                            // Action Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                visible: wifiRoot.isConnected
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 10
                                    color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                                    border.color: Theme.red
                                    border.width: 1
                                    
                                    Text { anchors.centerIn: parent; text: "Disconnect"; color: Theme.red; font.pixelSize: 12; font.weight: Font.Bold }
                                    MouseArea { 
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { Quickshell.execDetached(["nmcli", "device", "disconnect", "wlan0"]); refreshAll() }
                                        onPressed: parent.scale = 0.95
                                        onReleased: parent.scale = 1.0
                                    }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 10
                                    color: Theme.surface
                                    border.color: Theme.borderColor
                                    border.width: 1

                                    Text { anchors.centerIn: parent; text: "Forget Network"; color: Theme.text; font.pixelSize: 12; font.weight: Font.Bold }
                                    MouseArea { 
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { Quickshell.execDetached(["nmcli", "connection", "delete", wifiRoot.activeSSID]); refreshAll() }
                                        onPressed: parent.scale = 0.95
                                        onReleased: parent.scale = 1.0
                                    }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                }
                            }
                        }
                    }


                    // ── SECTION 8: SETTINGS & PREFERENCES CARD ──
                    Rectangle {
                        width: parent.width - 4
                        height: 60
                        radius: 14
                        color: Theme.overlay
                        border.color: Theme.borderColor
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16

                            Text { text: "Show Speed In Bar"; color: Theme.text; font.pixelSize: 13; font.weight: Font.Bold; Layout.fillWidth: true }
                            Switch {
                                checked: Globals.showWifiSpeed
                                onToggled: Globals.showWifiSpeed = checked
                            }
                        }
                    }


                    // ── SECTION 5: NEARBY NETWORKS LIST ──
                    Column {
                        width: parent.width - 4
                        spacing: 10
                        visible: !wifiRoot.showSavedNetworks && wifiRoot.wifiPowered

                        RowLayout {
                            width: parent.width
                            height: 24
                            Text { text: "Discovered Networks"; color: Theme.text; font.pixelSize: 12; font.weight: Font.Bold; Layout.leftMargin: 4 }
                            Item { Layout.fillWidth: true }
                            Text { text: wifiRoot.nearbyNetworks.length + " found"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.Bold; Layout.rightMargin: 4 }
                        }

                        Repeater {
                            model: wifiRoot.nearbyNetworks

                            delegate: Rectangle {
                                width: parent.width
                                height: 80
                                radius: 14

                                color: nearbyRowHover.containsMouse ? Theme.overlay : Qt.rgba(1,1,1,0.02)
                                border.color: Theme.borderColor
                                border.width: 1
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                scale: nearbyRowHover.containsMouse ? 1.01 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 16

                                    ColumnLayout {
                                        spacing: 2
                                        Text { text: signalIcon(modelData.signal); color: signalColor(modelData.signal); font.pixelSize: 22; Layout.alignment: Qt.AlignHCenter }
                                        Text { text: modelData.signal + "%"; color: Theme.muted; font.pixelSize: 10; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Text { text: modelData.ssid; color: Theme.text; font.pixelSize: 15; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
                                        RowLayout {
                                            spacing: 6
                                            Text { text: modelData.secure ? "󰌾 Secured" : "󰧵 Open"; color: Theme.muted; font.pixelSize: 11 }
                                        }
                                    }

                                    Rectangle {
                                        width: 86
                                        height: 34
                                        radius: 8
                                        color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.15)
                                        border.color: Theme.blue
                                        border.width: 1
                                        visible: nearbyRowHover.containsMouse

                                        Text { anchors.centerIn: parent; text: "Connect"; color: Theme.blue; font.pixelSize: 11; font.weight: Font.Bold }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.secure) {
                                                    wifiRoot.targetSSID = modelData.ssid
                                                    wifiRoot.targetPassword = ""
                                                } else {
                                                    Quickshell.execDetached(["nmcli", "device", "wifi", "connect", modelData.ssid])
                                                    refreshAll()
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: nearbyRowHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    propagateComposedEvents: true
                                }
                            }
                        }
                    }

                    // ── SECTION 4: SAVED NETWORKS LIST ──
                    Column {
                        width: parent.width - 4
                        spacing: 10
                        visible: wifiRoot.showSavedNetworks && wifiRoot.wifiPowered

                        RowLayout {
                            width: parent.width
                            height: 24
                            Text { text: "Stored Profiles"; color: Theme.text; font.pixelSize: 12; font.weight: Font.Bold; Layout.leftMargin: 4 }
                            Item { Layout.fillWidth: true }
                            Text { text: wifiRoot.savedNetworks.length + " profiles"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.Bold; Layout.rightMargin: 4 }
                        }

                        Repeater {
                            model: wifiRoot.savedNetworks

                            delegate: Rectangle {
                                width: parent.width
                                height: 68
                                radius: 14

                                color: savedRowHover.containsMouse ? Theme.overlay : Qt.rgba(1,1,1,0.02)
                                border.color: Theme.borderColor
                                border.width: 1
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                scale: savedRowHover.containsMouse ? 1.01 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 16

                                    Text { text: "󰤨"; color: Theme.blue; font.pixelSize: 22 }

                                    Text {
                                        text: modelData.ssid
                                        color: Theme.text
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        spacing: 10
                                        visible: savedRowHover.containsMouse

                                        Rectangle {
                                            width: 80; height: 34; radius: 8
                                            color: Theme.surface; border.color: Theme.borderColor; border.width: 1
                                            Text { anchors.centerIn: parent; text: "Forget"; color: Theme.text; font.pixelSize: 11; font.weight: Font.Bold }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: { Quickshell.execDetached(["nmcli", "connection", "delete", modelData.ssid]); refreshAll() }
                                            }
                                        }

                                        Rectangle {
                                            width: 90; height: 34; radius: 8
                                            color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.15); border.color: Theme.blue; border.width: 1
                                            Text { anchors.centerIn: parent; text: "Connect"; color: Theme.blue; font.pixelSize: 11; font.weight: Font.Bold }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: { Quickshell.execDetached(["nmcli", "connection", "up", "id", modelData.ssid]); refreshAll() }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: savedRowHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    propagateComposedEvents: true
                                }
                            }
                        }
                    }
                }
            }

            // ── SECTION 7: BOTTOM ACTIONS ROW ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Rectangle {
                    Layout.fillWidth: true; height: 48; radius: 12
                    color: Theme.overlay; border.color: Theme.borderColor; border.width: 1
                    
                    RowLayout {
                        anchors.centerIn: parent; spacing: 10
                        Text {
                            text: "󰑐"; color: Theme.text; font.pixelSize: 16
                            RotationAnimator on rotation { running: wifiRoot.isScanning; from: 0; to: 360; duration: 800; loops: Animation.Infinite }
                        }
                        Text { text: "Refresh Layout"; color: Theme.text; font.pixelSize: 13; font.weight: Font.Bold }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: refreshAll()
                        onPressed: parent.scale = 0.95
                        onReleased: parent.scale = 1.0
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 48; radius: 12
                    color: networkManagerMouse.containsMouse ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.20) : Theme.overlay
                    border.color: Theme.blue; border.width: 1
                    
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.centerIn: parent; spacing: 10
                        Text { text: "󰛳"; color: Theme.blue; font.pixelSize: 16 }
                        Text { text: "Network Settings"; color: Theme.blue; font.pixelSize: 13; font.weight: Font.Bold }
                    }

                    MouseArea {
                        id: networkManagerMouse
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { Globals.wifiOpen = false; Quickshell.execDetached(["kitty", "-e", "nmtui"]) }
                        onPressed: parent.scale = 0.95
                        onReleased: parent.scale = 1.0
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }
            }
        }
    }

    // ==========================================
    // SECTION 6: ABSOLUTE PASSWORD MODAL
    // ==========================================
    // Escapes the layout flow entirely. z: 9999 guarantees it sits above everything.
    Rectangle {
        id: passwordModalOverlay
        anchors.fill: parent
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.85) // Deep blur/dim effect
        visible: wifiRoot.targetSSID.length > 0
        z: 9999 

        // Intercept all stray clicks so they don't pass through to the lists
        MouseArea { 
            anchors.fill: parent
            hoverEnabled: true 
            preventStealing: true
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 64
            height: 200
            radius: 20
            color: Theme.surface
            border.color: Theme.borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Authentication Required"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.Black
                    }

                    Text {
                        text: "Connecting to: " + wifiRoot.targetSSID
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }

                // High-Reliability Native TextInput Wrapper
                Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    radius: 12
                    color: Theme.surface
                    border.width: 1
                    border.color: passwordInput.activeFocus ? Theme.blue : Theme.overlay

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.pixelSize: 14
                        
                        focus: true
                        selectByMouse: true
                        echoMode: TextInput.Password

                        onTextChanged: {
                            wifiRoot.targetPassword = text
                        }

                        // Connect on Enter
                        Keys.onReturnPressed: {
                            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", wifiRoot.targetSSID, "password", wifiRoot.targetPassword])
                            wifiRoot.targetSSID = ""
                            wifiRoot.targetPassword = ""
                            passwordInput.text = ""
                            wifiRoot.refreshWifi()
                        }

                        // Close on Escape
                        Keys.onEscapePressed: {
                            wifiRoot.targetSSID = ""
                            wifiRoot.targetPassword = ""
                            passwordInput.text = ""
                        }

                        // Force Keyboard Focus automatically upon visibility
                        onVisibleChanged: {
                            if (visible) forceActiveFocus()
                        }

                        Component.onCompleted: {
                            forceActiveFocus()
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        radius: 10
                        color: Theme.overlay
                        border.color: Theme.borderColor
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiRoot.targetSSID = ""
                                wifiRoot.targetPassword = ""
                                passwordInput.text = ""
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        radius: 10
                        color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.15)
                        border.color: Theme.blue
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: Theme.blue
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["nmcli", "device", "wifi", "connect", wifiRoot.targetSSID, "password", wifiRoot.targetPassword])
                                wifiRoot.targetSSID = ""
                                wifiRoot.targetPassword = ""
                                passwordInput.text = ""
                                wifiRoot.refreshWifi()
                            }
                        }
                    }
                }
            }
        }
    }
}