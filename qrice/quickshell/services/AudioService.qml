pragma Singleton

import QtQuick

QtObject {
    property int volume: 50
    property bool muted: false

    function volumeIcon() {
        if (muted)
            return "󰖁"

        if (volume < 30)
            return "󰕿"

        if (volume < 70)
            return "󰖀"

        return "󰕾"
    }
}