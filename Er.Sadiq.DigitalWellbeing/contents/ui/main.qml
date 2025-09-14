import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.core as PlasmaCore
import "logic.js" as Logic

PlasmoidItem {
    id: root
    width: 300
    height: 110
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // --- tweakable constraints (change these if you need a different minimum)
    property int minCardWidth: 120
    property int minCardHeight: 44
    property real horizontalPaddingFactor: 0.06
    property real verticalPaddingFactor: 0.06

    /* public state (uptime) */
    property real uptimeSeconds: 0
    property string uptimeText: "…"
    property bool haveSystemMonitor: false

    /* break timer state */
    property int remainingSeconds: 0
    property bool showBreakOverlay: false

    FontLoader { id: lorenzoSans; source: "../fonts/BitcountRegular.ttf" }

    /* -------------------------
     *       helpers (unchanged logic)
     *       ------------------------- */
    function getBreakIntervalMinutes() {
        var mins = 20
        if (plasmoid && plasmoid.configuration && plasmoid.configuration.breakInterval !== undefined) {
            var c = Number(plasmoid.configuration.breakInterval)
            if (!isNaN(c) && c > 0) mins = Math.floor(c)
        }
        return Math.max(1, mins)
    }
    function getBgColor() {
        if (plasmoid && plasmoid.configuration && plasmoid.configuration.backgroundColor)
            return plasmoid.configuration.backgroundColor
            return "#ffffff"
    }
    function getTextColor() {
        if (plasmoid && plasmoid.configuration && plasmoid.configuration.textColor)
            return plasmoid.configuration.textColor
            return "#000000"
    }

    function resetBreakTimer() {
        var mins = getBreakIntervalMinutes()
        root.remainingSeconds = mins * 60
        breakTimer.running = true
        root.showBreakOverlay = false
    }

    /* -------------------------
     *       data sources & timers
     *       (kept as in your code)
     *       ------------------------- */
    Plasma5Support.DataSource {
        id: sysmon; engine: "systemmonitor"; connectedSources: ["system/uptime"]; interval: 60000
        onDataChanged: {
            var n = Logic.extractUptime(sysmon.data)
            if (n !== null) {
                root.uptimeSeconds = n
                root.uptimeText = Logic.formatUptime(n)
                root.haveSystemMonitor = true
            }
        }
    }

    Plasma5Support.DataSource {
        id: executor; engine: "executable"; connectedSources: []
        onNewData: function(sourceName, data) {
            if (!data) return
                var secs = Logic.parseProcUptime(data["stdout"])
                if (secs !== null) {
                    root.uptimeSeconds = secs
                    root.uptimeText = Logic.formatUptime(secs)
                }
                executor.disconnectSource(sourceName)
        }
        function execCmd(cmd) { executor.connectSource(cmd) }
    }

    Timer { id: fallbackTimer; interval: 300; repeat: false; onTriggered: {
        if (!root.haveSystemMonitor) executor.execCmd("/bin/cat /proc/uptime")
    }}

    Timer { id: breakTimer; interval: 1000; repeat: true; running: true; onTriggered: {
        if (root.remainingSeconds > 0) root.remainingSeconds--
            else {
                breakTimer.running = false
                root.showBreakOverlay = true
                overlayTimer.start()
            }
    }}

    Timer { id: overlayTimer; interval: 5000; repeat: false; onTriggered: {
        root.showBreakOverlay = false
        resetBreakTimer()
    }}

    Component.onCompleted: {
        fallbackTimer.start()
        resetBreakTimer()
    }

    Connections {
        target: plasmoid.configuration
        onBreakIntervalChanged: resetBreakTimer()
        onBackgroundColorChanged: {}
        onTextColorChanged: {}
    }

    /* -------------------------
     *       Visual card: centered & constrained
     *       ------------------------- */
    Rectangle {
        id: card
        anchors.centerIn: parent
        color: getBgColor()
        clip: true

        // computed paddings based on root size
        property real hPad: Math.max(8, root.width * horizontalPaddingFactor)
        property real vPad: Math.max(6, root.height * verticalPaddingFactor)

        // keep card within available space but respect minimums
        width: Math.max(minCardWidth, Math.min(root.width - 2 * hPad, root.width))
        height: Math.max(minCardHeight, Math.min(root.height - 2 * vPad, root.height))

        // keep a pill/radius but avoid becoming a perfect circle on extremely narrow containers
        radius: Math.min(height / 2, width * 0.25)

        /* Layout: two columns, centered content */
        GridLayout {
            id: grid
            anchors.fill: parent
            anchors.leftMargin: card.hPad
            anchors.rightMargin: card.hPad
            anchors.topMargin: Math.max(2, card.height * 0.05)    // TOP margin is smaller & proportional
            anchors.bottomMargin: Math.max(2, card.height * 0.05)
            columns: 2
            columnSpacing: Math.max(6, card.width * 0.03)
            rowSpacing: Math.max(4, card.height * 0.03)

            // LEFT column (centered horizontally & vertically)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                spacing: card.height * 0.02

                Text {
                    text: "Screen Time"
                    font.family: lorenzoSans.name
                    font.pointSize: Math.max(10, card.height * 0.18)
                    font.bold: true
                    color: getTextColor()
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                Text {
                    text: root.uptimeText
                    font.family: lorenzoSans.name
                    font.pointSize: Math.max(11, card.height * 0.22)
                    color: getTextColor()
                    opacity: 0.85
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            // RIGHT column (centered horizontally & vertically)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                spacing: card.height * 0.02

                Text {
                    id: countdown
                    text: Logic.formatCountdown(root.remainingSeconds)
                    font.family: lorenzoSans.name
                    font.pointSize: Math.max(11, card.height * 0.2)
                    font.bold: true
                    color: getTextColor()
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                // responsive progress bar
                Rectangle {
                    Layout.fillWidth: true
                    height: Math.max(6, card.height * 0.08)
                    radius: Math.min(height/2, width * 0.2)
                    color: Qt.lighter(getBgColor(), 1.08)
                    border.width: 0

                    Rectangle {
                        id: progressFill
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        width: {
                            var total = Math.max(1, getBreakIntervalMinutes() * 60)
                            var frac = (total - root.remainingSeconds) / total
                            return parent.width * Math.max(0, Math.min(1, frac))
                        }
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: getTextColor() }
                            GradientStop { position: 1.0; color: Qt.lighter(getTextColor(), 1.2) }
                        }
                        opacity: 0.18

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    }
                }
            }
        }

        /* Break overlay: centered & responsive */
        Rectangle {
            id: overlay
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            visible: root.showBreakOverlay || overlay.opacity > 0
            opacity: root.showBreakOverlay ? 1 : 0
            z: 10
            radius: card.radius
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Column {
                anchors.centerIn: parent
                spacing: card.height * 0.04
                Text {
                    text: "⏳ Time's up!"
                    font.pointSize: Math.max(12, card.height * 0.18)
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: "Take a short break."
                    font.pointSize: Math.max(10, card.height * 0.14)
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    } // card
}
