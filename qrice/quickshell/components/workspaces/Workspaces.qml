import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../"

Item {
    id: root

    // ── Config ─────────────────────────────────────────────
    readonly property int btnSize:    32      // size of each workspace slot
    readonly property int activeMargin: 2     // shrink active indicator inward

    // ── Derived state ──────────────────────────────────────
    // Build sorted list of all known workspace IDs
    property var knownIds: {
        var ids = Hyprland.workspaces.values.map(ws => ws.id).filter(id => id > 0)
        var active = Hyprland.focusedWorkspace?.id ?? 1
        if (ids.indexOf(active) === -1) ids.push(active)
        // Always keep a "next" empty slot past the highest
        var maxId = Math.max.apply(null, ids.length ? ids : [1])
        if (ids.indexOf(maxId + 1) === -1) ids.push(maxId + 1)
        ids.sort((a, b) => a - b)
        return ids
    }

    property int activeId:   Hyprland.focusedWorkspace?.id ?? 1
    property int activeIdx:  knownIds.indexOf(activeId)

    implicitWidth:  btnSize * knownIds.length
    implicitHeight: btnSize

    // Smooth width change as workspaces are added/removed
    Behavior on implicitWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // ── Scroll to switch ───────────────────────────────────
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch("hl.dsp.focus({workspace = \"r+1\"})")
            else
                Hyprland.dispatch("hl.dsp.focus({workspace = \"r-1\"})")
        }
    }

    // ── Layer 1: Occupied background pills ────────────────
    // Connected adjacent occupied workspaces merge into one pill
    Row {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.knownIds.length

            Rectangle {
                id: occRect
                width:  root.btnSize
                height: root.btnSize

                property int wsId:      root.knownIds[index]
                property bool occupied: Hyprland.workspaces.values.some(ws => ws.id === wsId)
                property bool isActive: root.activeId === wsId

                // Merge with neighbours that are also occupied (and not active)
                property bool mergeLeft: index > 0 && Hyprland.workspaces.values.some(
                    ws => ws.id === root.knownIds[index - 1]
                ) && root.activeId !== root.knownIds[index - 1]

                property bool mergeRight: index < root.knownIds.length - 1 && Hyprland.workspaces.values.some(
                    ws => ws.id === root.knownIds[index + 1]
                ) && root.activeId !== root.knownIds[index + 1]

                // Only show for occupied non-active workspaces
                opacity: (occupied && !isActive) ? 1 : 0

                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.65)

                topLeftRadius:    mergeLeft  ? 0 : height / 2
                bottomLeftRadius: mergeLeft  ? 0 : height / 2
                topRightRadius:   mergeRight ? 0 : height / 2
                bottomRightRadius: mergeRight ? 0 : height / 2

                Behavior on opacity       { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on topLeftRadius    { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on bottomLeftRadius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on topRightRadius   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on bottomRightRadius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ── Layer 2: Active indicator (sliding pill) ──────────
    Rectangle {
        id: activeIndicator
        z: 2

        property real targetX: root.activeIdx * root.btnSize + root.activeMargin
        property real targetW: root.btnSize - root.activeMargin * 2

        x:      targetX
        y:      root.activeMargin
        width:  targetW
        height: root.btnSize - root.activeMargin * 2
        radius: height / 2
        color:  Theme.accent

        // Stretchy spring animation: briefly widens toward target then snaps
        Behavior on x {
            SmoothedAnimation { velocity: root.btnSize * 12; duration: 260; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            SmoothedAnimation { velocity: root.btnSize * 14; duration: 200; easing.type: Easing.OutCubic }
        }
    }

    // ── Layer 3: Numbers / labels ─────────────────────────
    Row {
        anchors.fill: parent
        spacing: 0
        z: 3

        Repeater {
            model: root.knownIds.length

            Item {
                id: wsBtn
                width:  root.btnSize
                height: root.btnSize

                property int  wsId:      root.knownIds[index]
                property bool isActive:  root.activeId === wsId
                property bool isOccupied: Hyprland.workspaces.values.some(ws => ws.id === wsId)
                property bool isHovered: ma.containsMouse

                // Number label
                Text {
                    anchors.centerIn: parent
                    text: wsBtn.wsId
                    font.family:   Theme.fontFamily
                    font.pixelSize: 14
                    font.weight:   wsBtn.isActive ? Font.Bold : Font.Medium
                    color: wsBtn.isActive
                        ? Theme.base
                        : wsBtn.isHovered
                            ? Theme.text
                            : wsBtn.isOccupied
                                ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.85)
                                : Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.5)

                    Behavior on color { ColorAnimation { duration: 130 } }
                }

                // Hover highlight ring
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: "transparent"
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b,
                                          wsBtn.isHovered && !wsBtn.isActive ? 0.35 : 0)
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    // ✅ This is the correct API — same as End-4
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({workspace = ${wsBtn.wsId}})`)
                }
            }
        }
    }
}
