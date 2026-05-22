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
    property bool   isDeviceConnected: false
    property bool   bluetoothEnabled:  true
    property bool   discoverable:      false
    property bool   pairable:          false
    property bool   scanning:          false

    // ── SECTION EXPANSION ──
    property bool connectedExpanded: true
    property bool savedExpanded:     true
    property bool nearbyExpanded:    true

    // ── DEVICE MODELS ──
    property var pairedDevices: []
    property var nearbyDevices: []

    // ── STATISTICS ──
    property int connectedCount: 0
    property int pairedCount:    0
    property int nearbyCount:    0

    // ── SEARCH ──
    property string searchText: ""

    // ── COLORS ──
    property color cardBg:    Qt.rgba(1, 1, 1, 0.05)
    property color cardHover: Theme.overlay
    property color successBg: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.15)
    property color dangerBg:  Qt.rgba(Theme.red.r,   Theme.red.g,   Theme.red.b,   0.15)
    property color blueBg:    Qt.rgba(Theme.blue.r,  Theme.blue.g,  Theme.blue.b,  0.15)

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

    function signalText(rssi) {
        if (rssi > -60) return "Strong"
        if (rssi > -70) return "Good"
        if (rssi > -80) return "Fair"
        return "Weak"
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

    // Action runner — no stdout needed, just fires commands
    Process {
        id: btActionProc
    }

    // BT adapter state (power / discoverable / pairable)
    Process {
        id: btStateProc
        command: ["sh", "-c", "bluetoothctl show"]
        stdout: StdioCollector {
            onStreamFinished: {
                // FIX: StdioCollector exposes `text`, not `txt`
                bluetoothEnabled = text.indexOf("Powered: yes")       >= 0
                discoverable     = text.indexOf("Discoverable: yes")  >= 0
                pairable         = text.indexOf("Pairable: yes")      >= 0
            }
        }
    }

    // Currently connected device
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
                } else {
                    connectedMac      = ""
                    connectedDevice   = ""
                    isDeviceConnected = false
                    connectedCount    = 0
                }
            }
        }
    }

    // Paired device list
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

    // Nearby device scanner (runs bluetoothctl scan then lists)
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

    // Fast poll: connected state + BT power every 3 s
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

    // Stats sync every 5 s
    Timer {
        interval: 5000
        running:  Globals.bluetoothOpen
        repeat:   true
        onTriggered: refreshAll()
    }

    // Background rescan every 30 s
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
    // ROOT LAYOUT
    // ────────────────────────────────────────────────

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // ── HEADER: POWER TOGGLE ────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 58; radius: 14
            color: Theme.overlay
            border.color: Theme.borderColor; border.width: 1

            RowLayout {
                anchors.fill:        parent
                anchors.leftMargin:  16
                anchors.rightMargin: 16
                spacing: 12

                Text {
                    text:           "󰂯"
                    color:          bluetoothEnabled ? Theme.blue : Theme.muted
                    font.pixelSize: 22
                }

                Text {
                    text:           "Bluetooth"
                    color:          Theme.text
                    font.pixelSize: 14
                    font.weight:    Font.Black
                }

                Item { Layout.fillWidth: true }

                // iOS-style toggle switch
                Rectangle {
                    id: powerToggle
                    width: 58; height: 30; radius: 15
                    color: bluetoothEnabled ? Theme.blue : Theme.muted

                    Behavior on color { ColorAnimation { duration: 160 } }

                    Rectangle {
                        width: 24; height: 24; radius: 12
                        y: 3; color: "white"
                        x: bluetoothEnabled ? 31 : 3
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
                    }

                    // Click animation
                    scale: powerToggleMouse.pressed ? 0.93 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    MouseArea {
                        id: powerToggleMouse
                        anchors.fill: parent
                        onClicked: btCmd("bluetoothctl power " + (bluetoothEnabled ? "off" : "on"))
                    }
                }
            }
        }


        // ── HERO CARD ───────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 180; radius: 18
            color: cardBg; border.color: Theme.borderColor; border.width: 1

            ColumnLayout {
                anchors.fill:    parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // Device icon circle
                    Rectangle {
                        width: 78; height: 78; radius: 39
                        color: isDeviceConnected ? blueBg : Theme.overlay
                        Behavior on color { ColorAnimation { duration: 300 } }

                        Text {
                            anchors.centerIn: parent
                            text:           isDeviceConnected ? "󰂱" : "󰂯"
                            color:          isDeviceConnected ? Theme.blue : Theme.muted
                            font.pixelSize: 38
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Text {
                            text:             isDeviceConnected ? connectedDevice : "Bluetooth Ready"
                            color:            Theme.text
                            font.pixelSize:   17; font.weight: Font.Black
                            elide:            Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Connected pill badge
                        Rectangle {
                            visible:       isDeviceConnected
                            height:        26; radius: 999
                            color:         successBg
                            implicitWidth: heroStatusText.implicitWidth + 22

                            Text {
                                id: heroStatusText
                                anchors.centerIn: parent
                                text:           "● Connected"
                                color:          Theme.green
                                font.pixelSize: 11; font.weight: Font.Bold
                            }
                        }

                        Text {
                            visible:        isDeviceConnected
                            text:           "Bluetooth Audio Device"
                            color:          Theme.subtext
                            font.pixelSize: 11
                        }

                        Text {
                            visible:        !isDeviceConnected
                            text:           "No device connected"
                            color:          Theme.muted
                            font.pixelSize: 11
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Disconnect + Refresh row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true; height: 34; radius: 10
                        visible:      isDeviceConnected
                        color:        dangerBg
                        border.color: Theme.red; border.width: 1
                        scale: disconnectMouse.pressed ? 0.94 : 1.0
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text:           "󰂲 Disconnect"
                            color:          Theme.red
                            font.pixelSize: 11; font.weight: Font.Bold
                        }
                        MouseArea {
                            id: disconnectMouse
                            anchors.fill: parent
                            onClicked:    btCmd("bluetoothctl disconnect '" + connectedMac + "'")
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 34; radius: 10
                        color:        blueBg
                        border.color: Theme.blue; border.width: 1
                        scale: refreshMouse.pressed ? 0.94 : 1.0
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text:           "󰑐 Refresh"
                            color:          Theme.blue
                            font.pixelSize: 11; font.weight: Font.Bold
                        }
                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            onClicked: { scanning = true; scanProc.running = true }
                        }
                    }
                }
            }
        }


        // ── SCROLLABLE DEVICE LISTS ─────────────────
        ScrollView {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip:              true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width:   parent.width
                spacing: 8

                // ════════════════════════════════════
                // SAVED DEVICES SECTION
                // ════════════════════════════════════

                // Section header
                Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 12
                    color: Theme.overlay; border.color: Theme.borderColor; border.width: 1
                    scale: savedHeaderMouse.pressed ? 0.98 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    RowLayout {
                        anchors.fill:        parent
                        anchors.leftMargin:  14
                        anchors.rightMargin: 14

                        Text {
                            text:           savedExpanded ? "▼" : "▶"
                            color:          Theme.blue
                            font.pixelSize: 11; font.weight: Font.Black
                        }
                        Text {
                            text:           "Saved Devices"
                            color:          Theme.text
                            font.pixelSize: 13; font.weight: Font.Black
                        }
                        Item { Layout.fillWidth: true }

                        Rectangle {
                            radius: 999; height: 22; color: blueBg
                            implicitWidth: savedBadge.implicitWidth + 18
                            Text {
                                id:             savedBadge
                                anchors.centerIn: parent
                                text:           pairedDevices.length
                                color:          Theme.blue
                                font.pixelSize: 10; font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        id: savedHeaderMouse
                        anchors.fill: parent
                        onClicked:    savedExpanded = !savedExpanded
                    }
                }

                // Collapsible content
                Item {
                    Layout.fillWidth: true
                    implicitHeight:   savedExpanded ? savedColumn.implicitHeight : 0
                    clip: true
                    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        id:      savedColumn
                        width:   parent.width
                        spacing: 6

                        Repeater {
                            model: pairedDevices.filter(function(d) {
                                return searchText.length === 0 ||
                                       d.name.toLowerCase().includes(searchText.toLowerCase()) ||
                                       d.mac.toLowerCase().includes(searchText.toLowerCase())
                            })

                            delegate: Rectangle {
                                id:               savedCard
                                Layout.fillWidth: true
                                height:           82; radius: 14
                                opacity:          0

                                // Stored copy of modelData fields so buttons can
                                // safely read them even after model updates.
                                // FIX: this is the key reason Connect/Forget failed —
                                // modelData can become undefined inside nested closures
                                // when the Repeater model refreshes. Snapshot it here.
                                property string deviceMac:       modelData.mac
                                property string deviceName:      modelData.name
                                property bool   deviceConnected: modelData.connected

                                Component.onCompleted: opacity = 1
                                Behavior on opacity { NumberAnimation { duration: 250 } }

                                color: cardHoverArea.containsMouse ? Theme.overlay : Theme.surface
                                border.color: deviceConnected ? Theme.green    : Theme.borderColor
                                border.width: deviceConnected ? 2              : 1

                                // Hover scale — only on the card itself, not buttons
                                scale: cardHoverArea.containsMouse ? 1.018 : 1.0
                                Behavior on scale { NumberAnimation { duration: 130 } }
                                Behavior on color { ColorAnimation  { duration: 130 } }

                                RowLayout {
                                    anchors.fill:        parent
                                    anchors.leftMargin:  14
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    // Device icon circle
                                    Rectangle {
                                        width: 42; height: 42; radius: 21
                                        color: deviceConnected ? successBg : blueBg

                                        Text {
                                            anchors.centerIn: parent
                                            text:           deviceIcon(deviceName)
                                            color:          deviceConnected ? Theme.green : Theme.blue
                                            font.pixelSize: 18
                                        }
                                    }

                                    // Device info
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text:             deviceName
                                            color:            Theme.text
                                            font.pixelSize:   12; font.weight: Font.Bold
                                            Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                        Text {
                                            text:           deviceMac
                                            color:          Theme.muted
                                            font.pixelSize: 10
                                        }

                                        Rectangle {
                                            visible:       deviceConnected
                                            radius:        999; height: 18; color: successBg
                                            implicitWidth: connectedBadge.implicitWidth + 14
                                            Text {
                                                id:             connectedBadge
                                                anchors.centerIn: parent
                                                text:           "● Connected"
                                                color:          Theme.green
                                                font.pixelSize: 9; font.weight: Font.Bold
                                            }
                                        }
                                    }

                                    // Action buttons column
                                    // FIX: z:1 ensures these sit above the hover MouseArea
                                    ColumnLayout {
                                        spacing: 5
                                        z: 1

                                        // Connect / Reconnect
                                        Rectangle {
                                            id:     connectBtn
                                            width:  82; height: 28; radius: 8
                                            color:  connectBtnMouse.pressed
                                                        ? Qt.darker(successBg, 1.3)
                                                        : successBg
                                            scale:  connectBtnMouse.pressed ? 0.90 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 80 } }
                                            Behavior on color { ColorAnimation  { duration: 80 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text:           deviceConnected ? "Reconnect" : "Connect"
                                                color:          Theme.green
                                                font.pixelSize: 10; font.weight: Font.Bold
                                            }
                                            MouseArea {
                                                id:           connectBtnMouse
                                                anchors.fill: parent
                                                // FIX: use the snapshotted property, not modelData
                                                onClicked:    btCmd("bluetoothctl connect '" + deviceMac + "'")
                                            }
                                        }

                                        // Forget
                                        Rectangle {
                                            id:     forgetBtn
                                            width:  82; height: 28; radius: 8
                                            color:  forgetBtnMouse.pressed
                                                        ? Qt.darker(dangerBg, 1.3)
                                                        : dangerBg
                                            scale:  forgetBtnMouse.pressed ? 0.90 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 80 } }
                                            Behavior on color { ColorAnimation  { duration: 80 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text:           "Forget"
                                                color:          Theme.red
                                                font.pixelSize: 10; font.weight: Font.Bold
                                            }
                                            MouseArea {
                                                id:           forgetBtnMouse
                                                anchors.fill: parent
                                                // FIX: use the snapshotted property, not modelData
                                                onClicked:    btCmd("bluetoothctl remove '" + deviceMac + "'")
                                            }
                                        }
                                    }
                                }

                                // Hover detector — z:0 so it sits BELOW the buttons (z:1)
                                MouseArea {
                                    id:           cardHoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z:            0
                                    // Do NOT handle clicks here — buttons handle their own
                                    // Setting acceptedButtons to none lets clicks pass through
                                    // to child items (the buttons above)
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }

                // ════════════════════════════════════
                // NEARBY DEVICES SECTION
                // ════════════════════════════════════

                // Section header
                Rectangle {
                    Layout.fillWidth: true; height: 40; radius: 12
                    color: Theme.overlay; border.color: Theme.borderColor; border.width: 1
                    scale: nearbyHeaderMouse.pressed ? 0.98 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    RowLayout {
                        anchors.fill:        parent
                        anchors.leftMargin:  14
                        anchors.rightMargin: 14

                        Text {
                            text:           nearbyExpanded ? "▼" : "▶"
                            color:          Theme.yellow
                            font.pixelSize: 11; font.weight: Font.Black
                        }
                        Text {
                            text:           "Nearby Devices"
                            color:          Theme.text
                            font.pixelSize: 13; font.weight: Font.Black
                        }
                        Item { Layout.fillWidth: true }

                        Rectangle {
                            radius: 999; height: 22
                            color:         Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.15)
                            implicitWidth: nearbyBadge.implicitWidth + 18
                            Text {
                                id:             nearbyBadge
                                anchors.centerIn: parent
                                text:           nearbyDevices.length
                                color:          Theme.yellow
                                font.pixelSize: 10; font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        id: nearbyHeaderMouse
                        anchors.fill: parent
                        onClicked:    nearbyExpanded = !nearbyExpanded
                    }
                }

                // Collapsible content
                Item {
                    Layout.fillWidth: true
                    implicitHeight:   nearbyExpanded ? nearbyColumn.implicitHeight : 0
                    clip: true
                    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        id:      nearbyColumn
                        width:   parent.width
                        spacing: 6

                        // Empty state
                        ColumnLayout {
                            visible:          nearbyDevices.length === 0
                            Layout.fillWidth: true
                            spacing: 10

                            Item { height: 8 }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 72; height: 72; radius: 36; color: Theme.overlay

                                Text {
                                    anchors.centerIn: parent
                                    text:           "󰂲"
                                    color:          Theme.muted
                                    font.pixelSize: 36
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text:           "No Bluetooth devices nearby"
                                color:          Theme.subtext
                                font.pixelSize: 12; font.weight: Font.Bold
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text:           "Press Scan to search"
                                color:          Theme.muted
                                font.pixelSize: 11
                            }

                            Item { height: 8 }
                        }

                        Repeater {
                            model: nearbyDevices.filter(function(d) {
                                return searchText.length === 0 ||
                                       d.name.toLowerCase().includes(searchText.toLowerCase()) ||
                                       d.mac.toLowerCase().includes(searchText.toLowerCase())
                            })

                            delegate: Rectangle {
                                id:               nearbyCard
                                Layout.fillWidth: true
                                height:           72; radius: 14
                                opacity:          0

                                // Snapshot modelData same as saved cards
                                property string deviceMac:  modelData.mac
                                property string deviceName: modelData.name
                                property int    deviceRssi: modelData.rssi

                                Component.onCompleted: opacity = 1
                                Behavior on opacity { NumberAnimation { duration: 250 } }

                                color: nearbyHoverArea.containsMouse ? Theme.overlay : Theme.surface
                                border.color: Theme.borderColor; border.width: 1

                                scale: nearbyHoverArea.containsMouse ? 1.018 : 1.0
                                Behavior on scale { NumberAnimation { duration: 130 } }
                                Behavior on color { ColorAnimation  { duration: 130 } }

                                RowLayout {
                                    anchors.fill:        parent
                                    anchors.leftMargin:  14
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    // Device icon
                                    Rectangle {
                                        width: 42; height: 42; radius: 21; color: blueBg
                                        Text {
                                            anchors.centerIn: parent
                                            text:           deviceIcon(deviceName)
                                            color:          Theme.blue
                                            font.pixelSize: 18
                                        }
                                    }

                                    // Device info
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text:             deviceName
                                            color:            Theme.text
                                            font.pixelSize:   12; font.weight: Font.Bold
                                            Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                        Text {
                                            text:           deviceMac
                                            color:          Theme.muted
                                            font.pixelSize: 10
                                        }

                                        RowLayout {
                                            spacing: 5
                                            Text { text: signalIcon(deviceRssi); color: Theme.yellow; font.pixelSize: 11 }
                                            Text { text: signalText(deviceRssi); color: Theme.yellow; font.pixelSize: 10 }
                                        }
                                    }

                                    // Pair button — z:1 to sit above hover area
                                    Rectangle {
                                        id:     pairBtn
                                        width:  82; height: 30; radius: 8; z: 1
                                        color:  pairBtnMouse.pressed
                                                    ? Qt.darker(successBg, 1.3)
                                                    : successBg
                                        scale:  pairBtnMouse.pressed ? 0.90 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 80 } }
                                        Behavior on color { ColorAnimation  { duration: 80 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text:           "Pair"
                                            color:          Theme.green
                                            font.pixelSize: 10; font.weight: Font.Bold
                                        }
                                        MouseArea {
                                            id:           pairBtnMouse
                                            anchors.fill: parent
                                            onClicked:    btCmd("bluetoothctl pair '" + deviceMac + "'")
                                        }
                                    }
                                }

                                // Hover-only area — passes clicks through
                                MouseArea {
                                    id:              nearbyHoverArea
                                    anchors.fill:    parent
                                    hoverEnabled:    true
                                    z:               0
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }

                // Bottom padding inside scroll area
                Item { height: 4 }

            } // inner ColumnLayout
        } // ScrollView

        // ── FOOTER: ACTION BUTTONS ──────────────────
        Rectangle {
            Layout.fillWidth: true; height: 50; radius: 14
            color: Theme.overlay; border.color: Theme.borderColor; border.width: 1

            RowLayout {
                anchors.fill:        parent
                anchors.leftMargin:  10
                anchors.rightMargin: 10
                spacing: 8

                // Scan
                Rectangle {
                    Layout.fillWidth: true; height: 34; radius: 10
                    color: scanning ? Theme.blue : blueBg
                    scale: scanFooterMouse.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }
                    Behavior on color { ColorAnimation  { duration: 200 } }

                    Text {
                        anchors.centerIn: parent
                        text:           scanning ? "󰑐 Scanning..." : "󰑐 Scan"
                        color:          scanning ? "white"         : Theme.blue
                        font.pixelSize: 11; font.weight: Font.Bold
                    }
                    MouseArea {
                        id:      scanFooterMouse
                        anchors.fill: parent
                        enabled: !scanning
                        onClicked: { scanning = true; scanProc.running = true }
                    }
                }

                // Blueman Manager
                Rectangle {
                    Layout.fillWidth: true; height: 34; radius: 10; color: Theme.surface
                    scale: managerMouse.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text:           "󰂯 Manager"
                        color:          Theme.text
                        font.pixelSize: 11; font.weight: Font.Bold
                    }
                    MouseArea {
                        id:           managerMouse
                        anchors.fill: parent
                        onClicked:    Quickshell.execDetached(["blueman-manager"])
                    }
                }

                // Settings
                Rectangle {
                    Layout.fillWidth: true; height: 34; radius: 10; color: Theme.surface
                    scale: settingsMouse.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text:           "󰌍 Settings"
                        color:          Theme.text
                        font.pixelSize: 11; font.weight: Font.Bold
                    }
                    MouseArea {
                        id:           settingsMouse
                        anchors.fill: parent
                        onClicked:    Quickshell.execDetached(["gnome-control-center", "bluetooth"])
                    }
                }
            }
        }

    } // ColumnLayout
} // Item
