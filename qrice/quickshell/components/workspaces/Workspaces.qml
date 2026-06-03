import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../"

Item {
    id: root

    // ── Tokens ────────────────────────────────────────────
    readonly property int slotW: 38
    readonly property int slotH: 30
    readonly property int capsuleH: 30
    readonly property int pillPad: 3
    readonly property int trackPadH: 28

    // ── State ─────────────────────────────────────────────
    property var knownIds: {
        var occupied = Hyprland.workspaces.values
            .map(ws => ws.id)
            .filter(id => id > 0)

        var active = Hyprland.focusedWorkspace?.id ?? 1

        if (occupied.indexOf(active) === -1)
            occupied.push(active)

        var maxId = occupied.length
            ? Math.max.apply(null, occupied)
            : 1

        var total = Math.max(6, maxId + 1)

        var ids = []

        for (var i = 1; i <= total; i++)
            ids.push(i)

        return ids
    }

    property int activeId: Hyprland.focusedWorkspace?.id ?? 1
    property int activeIdx: Math.max(0, knownIds.indexOf(activeId))

    // ── Scroll ────────────────────────────────────────────
    property real scrollAccum: 0
    readonly property real scrollThresh: 60

    implicitWidth: slotW * knownIds.length
    implicitHeight: capsuleH

    Behavior on implicitWidth {
        SpringAnimation {
            spring: 4.0
            damping: 0.82
            epsilon: 0.5
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: (event) => {
            var delta = event.angleDelta.y

            if (Math.abs(delta) >= 120) {
                if (delta < 0)
                    Hyprland.dispatch(`hl.dsp.focus({workspace = "r+1"})`)
                else
                    Hyprland.dispatch(`hl.dsp.focus({workspace = "r-1"})`)

                root.scrollAccum = 0
                return
            }

            root.scrollAccum += delta

            if (root.scrollAccum <= -root.scrollThresh) {
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r+1"})`)
                root.scrollAccum = 0
            } else if (root.scrollAccum >= root.scrollThresh) {
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r-1"})`)
                root.scrollAccum = 0
            }
        }
    }

    // ── Background Track ──────────────────────────────────
    Rectangle {
        anchors.fill: parent

        radius: height / 2

        color: Qt.rgba(
            Theme.surface.r,
            Theme.surface.g,
            Theme.surface.b,
            0.28
        )

        border.width: 1

        border.color: Qt.rgba(
            Theme.borderColor.r,
            Theme.borderColor.g,
            Theme.borderColor.b,
            0.10
        )
    }

    // ── Active Pill ───────────────────────────────────────
    Rectangle {
        id: activePill

        z: 2

        readonly property real targetX:
            root.activeIdx * root.slotW + 3

        x: targetX

        y: 3

        width: root.slotW - 6

        height: root.capsuleH - 6

        radius: 12

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.lighter(Theme.accent, 1.05)
            }

            GradientStop {
                position: 1
                color: Theme.accent
            }
        }

        Rectangle {
            anchors.fill: parent

            radius: parent.radius

            color: Qt.rgba(
                1,
                1,
                1,
                0.05
            )
        }

        Behavior on x {
            SpringAnimation {
                spring: 4.2
                damping: 0.72
            }
        }
    }

    // ── Labels + Hit Areas ────────────────────────────────
    Row {
        anchors.fill: parent
        spacing: 0
        z: 3

        Repeater {
            model: root.knownIds.length

            Item {
                id: slot

                width: root.slotW
                height: root.capsuleH

                property int wsId: root.knownIds[index]

                property bool isActive:
                    root.activeId === wsId

                property bool isOccupied:
                    Hyprland.workspaces.values.some(
                        ws => ws.id === wsId
                    )

                property bool isHovered:
                    hitArea.containsMouse

                Text {
                    anchors.centerIn: parent

                    text: slot.wsId

                    font.family: Theme.fontFamily

                    font.pixelSize: 12

                    font.weight:
                        slot.isActive
                            ? Font.Bold
                            : Font.Medium

                    color:
                        slot.isActive
                            ? Theme.base
                            : slot.isOccupied
                                ? Qt.rgba(
                                    Theme.text.r,
                                    Theme.text.g,
                                    Theme.text.b,
                                    0.85
                                )
                                : Qt.rgba(
                                    Theme.subtext.r,
                                    Theme.subtext.g,
                                    Theme.subtext.b,
                                    0.40
                                )

                    scale:
                        slot.isHovered && !slot.isActive
                            ? 1.07
                            : 1.0

                    Behavior on scale {
                        SpringAnimation {
                            spring: 5
                            damping: 0.75
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    id: hitArea

                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    onClicked:
                        Hyprland.dispatch(
                            `hl.dsp.focus({workspace = ${slot.wsId}})`
                        )
                }
            }
        }
    }
}