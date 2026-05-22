pragma Singleton

import QtQuick

QtObject {
    property bool connected: false
    property string ssid: "Not Connected"
    property int signal: 0

    property string downSpeed: "0 KB/s"
    property string upSpeed: "0 KB/s"

    property var networks: []
}