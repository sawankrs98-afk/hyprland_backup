import Quickshell
import Quickshell.Wayland
import QtQuick

import "components"
import "popups/status"

ShellRoot {

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData

            implicitHeight: Theme.barHeight

            anchors {
                top: true
                left: true
                right: true
            }

            color: "transparent"

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "qs_topbar"

            Bar {
                anchors.fill: parent
            }
        }
    }

    Variants {
        model: (
            Globals.wifiOpen ||
            Globals.bluetoothOpen ||
            Globals.batteryOpen ||
            Globals.volumeOpen ||
            Globals.calendarOpen ||
            Globals.brightnessOpen
        ) ? Quickshell.screens : []

        PanelWindow {
            required property var modelData

            screen: modelData

            // Added volumeOpen so it gets the full 480px width
            implicitWidth:
                Globals.calendarOpen ? 640 :
                Globals.brightnessOpen ? 480 :
                Globals.bluetoothOpen ? 500 :
                Globals.volumeOpen ? 480 :
                Globals.wifiOpen ? 500 :
                Globals.batteryOpen ? 430 :
                300

            // Fixed the typo and matched the massive 340px height we built
            implicitHeight:
                Globals.calendarOpen ? 440 :
                Globals.brightnessOpen ? 340 :
                Globals.volumeOpen ? 200 :
                Globals.batteryOpen ? 560 :
                Globals.wifiOpen ? 800 :
                Globals.bluetoothOpen ? 700 :
                160

            anchors {
                top: true
                right: true
            }

            margins {
                top: Theme.barHeight + 2
                right: 6
            }

            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs_popup"

            StatusPopups {
                anchors.fill: parent
            }
        }
    }
}