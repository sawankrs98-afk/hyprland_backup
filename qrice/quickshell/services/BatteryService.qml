pragma Singleton

import QtQuick

QtObject {
    property int percentage: 100
    property bool charging: false
    property string status: "Unknown"

    function batteryIcon() {
        return "󰁹"
    }
}