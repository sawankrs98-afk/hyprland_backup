import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: btRoot

    implicitWidth: 520
    implicitHeight: 760

    // ── DEVICE STATE ──
    property string connectedDevice:   ""
    property string connectedMac:      ""
    property string connectedBattery:  "" // NEW: Tracks active device battery
    property bool   isDeviceConnected: false
    property bool   bluetoothEnabled:  true
    property bool   discoverable:      false
    property bool   pairable:          false
    property bool   scanning:          false

    // ── DEVICE MODELS ──
    property var pairedDevices: []
    property var nearbyDevices: []

    // ── STATISTICS ──
    property int connectedCount: 0
    property int pairedCount:    0
    property int nearbyCount:    0

    // ────────────────────────────────────────────────
    // HELPER FUNCTIONS
    // ────────────────────────────────────────────────

    function btCmd(cmd) {
        btActionProc.command = ["sh", "-c", cmd]
        btActionProc.running = true
        Qt.callLater(function() {
            btProc.running      = true
            pairedProc.running  = true
            btStateProc.running = true
        })
    }

    function deviceIcon(name) {
        let n = name.toLowerCase()
        if (n.includes("buds") || n.includes("audio") || n.includes("head") || n.includes("airpods")) return "󰋋"
        if (n.includes("keyboard"))  return "󰌌"
        if (n.includes("mouse"))     return "󰍽"
        if (n.includes("speaker"))   return "󰓃"
        if (n.includes("phone"))     return "󰄜"
        return "󰂯"
    }

    function signalIcon(rssi) {
        if (rssi > -60) return "󰤨"
        if (rssi > -70) return "󰤥"
        if (rssi > -80) return "󰤢"
        return "󰤟"
    }

    function refreshAll() {
        btProc.running      = true
        btStateProc.running = true
        pairedProc.running  = true
        connectedCount = isDeviceConnected ? 1 : 0
        pairedCount    = pairedDevices.length
        nearbyCount    = nearbyDevices.length
    }

    // ────────────────────────────────────────────────
    // PROCESSES
    // ────────────────────────────────────────────────

    Process { id: btActionProc }

    Process {
        id: btStateProc
        command: ["sh", "-c", "bluetoothctl show"]
        stdout: StdioCollector {
            onStreamFinished: {
                bluetoothEnabled = text.indexOf("Powered: yes")       >= 0
                discoverable     = text.indexOf("Discoverable: yes")  >= 0
                pairable         = text.indexOf("Pairable: yes")      >= 0
            }
        }
    }

    Process {
        id: btProc
        command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f2-"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                if (out.length > 0) {
                    let p             = out.split(" ")
                    connectedMac      = p[0]
                    connectedDevice   = p.slice(1).join(" ")
                    isDeviceConnected = true
                    connectedCount    = 1
                    batProc.running   = true // Fetch battery for this newly confirmed device
                } else {
                    connectedMac      = ""
                    connectedDevice   = ""
                    connectedBattery  = ""
                    isDeviceConnected = false
                    connectedCount    = 0
                }
            }
        }
    }

    // NEW: Background worker to safely extract device battery percentage
    Process {
        id: batProc
        command: ["sh", "-c", btRoot.connectedMac !== "" ? "bluetoothctl info " + btRoot.connectedMac + " | grep 'Battery Percentage' | awk -F'(' '{print $2}' | tr -d ')'" : "echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim()
                btRoot.connectedBattery = (out !== "") ? out + "%" : ""
            }
        }
    }

    Process {
        id: pairedProc
        command: ["sh", "-c", "bluetoothctl devices Paired"]
        stdout: StdioCollector {
            onStreamFinished: {
                let arr   = []
                let lines = text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    let p = lines[i].split(" ")
                    if (p.length >= 3)
                        arr.push({ mac: p[1], name: p.slice(2).join(" "), connected: p[1] === connectedMac })
                }
                arr.sort(function(a, b) {
                    if ( a.connected && !b.connected) return -1
                    if (!a.connected &&  b.connected) return  1
                    return 0
                })
                pairedDevices = arr
                pairedCount   = arr.length
            }
        }
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "timeout 8 bluetoothctl scan on >/dev/null 2>&1 && bluetoothctl devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                let arr   = []
                let lines = text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    let p = lines[i].split(" ")
                    if (p.length >= 3)
                        arr.push({ mac: p[1], name: p.slice(2).join(" "), rssi: -60 })
                }
                arr.sort(function(a, b) { return a.name.localeCompare(b.name) })
                nearbyDevices = arr
                nearbyCount   = arr.length
                scanning      = false
            }
        }
    }

    // ────────────────────────────────────────────────
    // TIMERS
    // ────────────────────────────────────────────────

    Timer {
        interval: 3000
        running:  Globals.bluetoothOpen
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            btProc.running      = true
            btStateProc.running = true
            pairedProc.running  = true
        }
    }

    Timer {
        interval: 5000
        running:  Globals.bluetoothOpen
        repeat:   true
        onTriggered: refreshAll()
    }

    Timer {
        interval: 30000
        running:  Globals.bluetoothOpen
        repeat:   true
        onTriggered: {
            if (!scanning) {
                scanning         = true
                scanProc.running = true
            }
        }
    }

    Component.onCompleted: {
        refreshAll()
        scanProc.running = true
        scanning         = true
    }

    // ────────────────────────────────────────────────
    // UI: MATERIAL YOU / PIXEL OS
    // ────────────────────────────────────────────────

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
                        text: "Bluetooth"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 28
                        font.weight: Font.Bold 
                    }
                    Text { 
                        text: btRoot.bluetoothEnabled ? (btRoot.isDeviceConnected ? "Connected to " + btRoot.connectedDevice : "Ready to connect") : "Bluetooth is turned off"
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    id: toggleSwitch
                    width: 52
                    height: 28
                    radius: 14
                    color: btRoot.bluetoothEnabled ? Theme.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                    Behavior on color { ColorAnimation { duration: 200 } }

                    scale: toggleMa.pressed ? 0.92 : (toggleMa.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: btRoot.bluetoothEnabled ? Theme.base : Theme.text
                        anchors.verticalCenter: parent.verticalCenter
                        x: btRoot.bluetoothEnabled ? parent.width - width - 4 : 4
                        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    MouseArea {
                        id: toggleMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btCmd("bluetoothctl power " + (btRoot.bluetoothEnabled ? "off" : "on"))
                    }
                }
            }

            // ── MAIN SCROLLABLE LIST ──
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                // CRITICAL FIX: Forces ScrollView contents to fill width, preventing truncation
                contentWidth: availableWidth 
                
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                visible: btRoot.bluetoothEnabled

                // CRITICAL FIX: Changed from ColumnLayout to standard Column to prevent width stealing
                Column {
                    width: parent.width
                    spacing: 8

                    // ── CONNECTED HERO CARD ──
                    Rectangle {
                        width: parent.width // Bind to Column width
                        implicitHeight: heroLayout.implicitHeight + 32
                        radius: 24
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                        visible: btRoot.isDeviceConnected

                        ColumnLayout {
                            id: heroLayout
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 16
                            spacing: 16

                            // Device Info Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                Text {
                                    text: deviceIcon(btRoot.connectedDevice)
                                    color: Theme.accent
                                    font.pixelSize: 32
                                    font.family: Theme.fontFamily
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { 
                                        text: btRoot.connectedDevice
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    
                                    // Status & Battery Row
                                    RowLayout {
                                        spacing: 6
                                        Text { 
                                            text: "Active connection"
                                            color: Theme.subtext
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12 
                                        }
                                        Text {
                                            visible: btRoot.connectedBattery !== ""
                                            text: "·"
                                            color: Theme.subtext
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12 
                                        }
                                        Text {
                                            visible: btRoot.connectedBattery !== ""
                                            text: "󰁹 " + btRoot.connectedBattery
                                            color: Theme.subtext
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12 
                                            font.weight: Font.Bold
                                        }
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
                                        onClicked: btCmd("bluetoothctl disconnect '" + btRoot.connectedMac + "'")
                                    }
                                }

                                // Forget Button
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 18
                                    color: heroForgetMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) : "transparent"
                                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)
                                    border.width: 1

                                    scale: heroForgetMa.pressed ? 0.98 : (heroForgetMa.containsMouse ? 1.02 : 1.0)
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
                                        id: heroForgetMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: btCmd("bluetoothctl remove '" + btRoot.connectedMac + "'")
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 8; visible: btRoot.isDeviceConnected }

                    // ── PAIRED DEVICES ──
                    Text {
                        text: "Saved Devices"
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        x: 8
                        visible: btRoot.pairedDevices.length > (btRoot.isDeviceConnected ? 1 : 0)
                    }

                    Repeater {
                        model: btRoot.pairedDevices

                        delegate: Rectangle {
                            width: parent.width // CRITICAL FIX: Forces full width
                            height: 64
                            radius: 16
                            // Hide from list if it's the currently connected device
                            visible: !modelData.connected
                            
                            color: pairedRowMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"
                            
                            scale: pairedRowMa.pressed ? 0.98 : (pairedRowMa.containsMouse ? 1.02 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            property string deviceMac:  modelData.mac
                            property string deviceName: modelData.name

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 16

                                Text {
                                    text: deviceIcon(deviceName)
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { 
                                        text: deviceName
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text { 
                                        text: "Saved device · Tap to connect"
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12 
                                    }
                                }

                                // Trailing Forget Button
                                Rectangle {
                                    height: 32
                                    implicitWidth: forgetText.implicitWidth + 24
                                    radius: 16
                                    color: forgetRowMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) : "transparent"
                                    visible: pairedRowMa.containsMouse
                                    
                                    Text {
                                        id: forgetText
                                        anchors.centerIn: parent
                                        text: "Forget"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                    }
                                    
                                    MouseArea {
                                        id: forgetRowMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: btCmd("bluetoothctl remove '" + deviceMac + "'")
                                    }
                                }
                            }

                            MouseArea {
                                id: pairedRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: btCmd("bluetoothctl connect '" + deviceMac + "'")
                            }
                        }
                    }

                    Item { width: 1; height: 12; visible: btRoot.nearbyDevices.length > 0 }

                    // ── AVAILABLE DEVICES ──
                    RowLayout {
                        width: parent.width
                        visible: btRoot.nearbyDevices.length > 0 || btRoot.scanning
                        
                        Text {
                            text: "Available Devices"
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            Layout.leftMargin: 8
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Scanning..."
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            visible: btRoot.scanning
                            Layout.rightMargin: 8
                        }
                    }

                    Repeater {
                        model: btRoot.nearbyDevices

                        delegate: Rectangle {
                            width: parent.width // CRITICAL FIX: Forces full width
                            height: 64
                            radius: 16
                            color: nearbyRowMa.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"
                            
                            scale: nearbyRowMa.pressed ? 0.98 : (nearbyRowMa.containsMouse ? 1.02 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            property string deviceMac:  modelData.mac
                            property string deviceName: modelData.name

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 16

                                Text {
                                    text: deviceIcon(deviceName)
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { 
                                        text: deviceName
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text { 
                                        text: "New device · Tap to pair"
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12 
                                    }
                                }
                            }

                            MouseArea {
                                id: nearbyRowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: btCmd("bluetoothctl pair '" + deviceMac + "'")
                            }
                        }
                    }

                    // Bottom padding buffer
                    Item { width: 1; height: 16 }
                }
            }
        }
    }
}