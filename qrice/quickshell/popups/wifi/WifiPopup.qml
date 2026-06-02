import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../../"

Item {
    id: wifiRoot

    implicitWidth: 540
    implicitHeight: 740

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

    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

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
        if (s >= 75) return Theme.accent
        if (s >= 50) return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.8)
        if (s >= 25) return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
        return Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
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

    // ── UNTOUCHED NETWORK LOGIC BLOCKS ────────────────────────────────────────

    Process {
        id: powerProc
        command: ["sh", "-c", "nmcli radio wifi"]
        stdout: StdioCollector {
            onStreamFinished: { 
                wifiRoot.wifiPowered = text.trim().toLowerCase() === "enabled" 
            }
        }
    }

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

                arr.sort((a, b) => b.signal - a.signal)
                wifiRoot.nearbyNetworks = arr
                wifiRoot.isScanning = false
            }
        }
    }

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

    Timer {
        interval: 5000
        running: Globals.wifiOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: refreshAll()
    }

    // ── UI REDESIGN: MATERIAL YOU / ANDROID 15 ─────────────────────────────────

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Theme.surface
        border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.4)
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // ── TOP HEADER & SWITCH ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { 
                        text: "Wi-Fi"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 28
                        font.weight: Font.Bold 
                    }
                    Text { 
                        text: wifiRoot.wifiPowered ? (wifiRoot.isConnected ? "Connected to network" : "Available networks") : "Wi-Fi is turned off"
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                    }
                }

                // Material Toggle Switch
                Rectangle {
                    id: toggleSwitch
                    width: 52
                    height: 28
                    radius: 14
                    color: wifiRoot.wifiPowered ? Theme.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                    Behavior on color { ColorAnimation { duration: 200 } }

                    scale: toggleMa.pressed ? 0.92 : (toggleMa.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: wifiRoot.wifiPowered ? Theme.base : Theme.text
                        anchors.verticalCenter: parent.verticalCenter
                        x: wifiRoot.wifiPowered ? parent.width - width - 4 : 4
                        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    MouseArea {
                        id: toggleMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["nmcli", "radio", "wifi", wifiRoot.wifiPowered ? "off" : "on"])
                            refreshAll()
                        }
                    }
                }
            }

            // ── CONNECTED HERO CARD ──
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heroLayout.implicitHeight + 32 // Dynamically fits content
                radius: 20
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                visible: wifiRoot.wifiPowered && wifiRoot.isConnected

                ColumnLayout {
                    id: heroLayout
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 16
                    spacing: 12

                    // Network Info Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Text {
                            text: signalIcon(wifiRoot.activeSignal)
                            color: Theme.accent
                            font.pixelSize: 28
                            font.family: Theme.fontFamily
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { 
                                text: wifiRoot.activeSSID
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text { 
                                text: wifiRoot.activeSecurity
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 12 
                            }
                        }

                        // Connected Pill
                        Rectangle {
                            height: 26
                            implicitWidth: connectedText.implicitWidth + 24
                            radius: 13
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                            Text { 
                                id: connectedText
                                anchors.centerIn: parent
                                text: "Connected"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold 
                            }
                        }
                    }

                    // Action Buttons Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Disconnect Button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 18
                            color: disconnectMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) : "transparent"
                            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)
                            border.width: 1

                            scale: disconnectMa.pressed ? 0.98 : (disconnectMa.containsMouse ? 1.02 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text { 
                                anchors.centerIn: parent
                                text: "Disconnect"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium 
                            }
                            MouseArea { 
                                id: disconnectMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { Quickshell.execDetached(["nmcli", "device", "disconnect", "wlan0"]); refreshAll() }
                            }
                        }

                        // Forget Button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 18
                            color: forgetMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) : "transparent"
                            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)
                            border.width: 1

                            scale: forgetMa.pressed ? 0.98 : (forgetMa.containsMouse ? 1.02 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text { 
                                anchors.centerIn: parent
                                text: "Forget"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium 
                            }
                            MouseArea { 
                                id: forgetMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { Quickshell.execDetached(["nmcli", "connection", "delete", wifiRoot.activeSSID]); refreshAll() }
                            }
                        }
                    }
                }
            }

            // ── NETWORK LIST ──
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                visible: wifiRoot.wifiPowered

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: wifiRoot.nearbyNetworks

                        delegate: Rectangle {
                            width:parent.width
                            height: 64
                            radius: 16
                            color: rowMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"
                            
                            scale: rowMa.pressed ? 0.98 : (rowMa.containsMouse ? 1.02 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 16

                                Text {
                                    text: signalIcon(modelData.signal)
                                    color: signalColor(modelData.signal)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { 
                                        text: modelData.ssid
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text { 
                                        text: modelData.secure ? "Secured · Tap to connect" : "Open network · Tap to connect"
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12 
                                    }
                                }
                                
                                // Lock icon indicator for secured networks
                                Text {
                                    visible: modelData.secure
                                    text: "󰌾"
                                    color: Theme.subtext
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                }
                            }

                            MouseArea {
                                id: rowMa
                                anchors.fill: parent
                                hoverEnabled: true
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

                    // Saved Networks Spacer / Header
                    Item { Layout.preferredHeight: 12; visible: wifiRoot.savedNetworks.length > 0 }
                    Text {
                        text: "Saved Networks"
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        Layout.leftMargin: 16
                        visible: wifiRoot.savedNetworks.length > 0
                    }
                    Item { Layout.preferredHeight: 4; visible: wifiRoot.savedNetworks.length > 0 }

                    Repeater {
                        model: wifiRoot.savedNetworks

                        delegate: Rectangle {
                            width:parent.width
                            height: 64
                            radius: 16
                            color: savedRowMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"
                            
                            scale: savedRowMa.pressed ? 0.98 : (savedRowMa.containsMouse ? 1.02 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 16

                                Text {
                                    text: "󰤨"
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { 
                                        text: modelData.ssid
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text { 
                                        text: "Saved network · Tap to connect"
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12 
                                    }
                                }
                            }

                            MouseArea {
                                id: savedRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["nmcli", "connection", "up", "id", modelData.ssid])
                                    refreshAll()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── PASSWORD MODAL OVERLAY (DYNAMIC HEIGHT FIX) ──────────────────────────

    Rectangle {
        id: passwordModalOverlay
        anchors.fill: parent
        radius: 24
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.85)
        visible: wifiRoot.targetSSID.length > 0
        z: 9999 

        MouseArea { 
            anchors.fill: parent
            hoverEnabled: true 
            preventStealing: true
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 64
            implicitHeight: modalLayout.implicitHeight + 48 // Dynamically scales to fit inputs + padding
            radius: 24
            color: Theme.surface
            border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.4)
            border.width: 1

            ColumnLayout {
                id: modalLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 24
                spacing: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Enter Password"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Connecting to " + wifiRoot.targetSSID
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 16
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    border.width: 2
                    border.color: passwordInput.activeFocus ? Theme.accent : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        
                        focus: passwordModalOverlay.visible
                        selectByMouse: true
                        echoMode: TextInput.Password

                        onTextChanged: {
                            wifiRoot.targetPassword = text
                        }

                        Keys.onReturnPressed: {
                            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", wifiRoot.targetSSID, "password", wifiRoot.targetPassword])
                            wifiRoot.targetSSID = ""
                            wifiRoot.targetPassword = ""
                            passwordInput.text = ""
                            wifiRoot.refreshAll()
                        }

                        Keys.onEscapePressed: {
                            wifiRoot.targetSSID = ""
                            wifiRoot.targetPassword = ""
                            passwordInput.text = ""
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: passwordInput.forceActiveFocus()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Cancel Button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 20
                        color: cancelMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) : "transparent"
                        
                        scale: cancelMa.pressed ? 0.98 : (cancelMa.containsMouse ? 1.02 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            id: cancelMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiRoot.targetSSID = ""
                                wifiRoot.targetPassword = ""
                                passwordInput.text = ""
                            }
                        }
                    }

                    // Connect Button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 20
                        color: connectMa.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.8) : Theme.accent

                        scale: connectMa.pressed ? 0.98 : (connectMa.containsMouse ? 1.02 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: Theme.base
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            id: connectMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["nmcli", "device", "wifi", "connect", wifiRoot.targetSSID, "password", wifiRoot.targetPassword])
                                wifiRoot.targetSSID = ""
                                wifiRoot.targetPassword = ""
                                passwordInput.text = ""
                                wifiRoot.refreshAll()
                            }
                        }
                    }
                }
            }
        }
    }
}