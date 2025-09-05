import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import "logic.js" as Logic

PlasmoidItem {
    id: root
    width: 300
    height: 110
    

    /* public state (uptime) */
    property real uptimeSeconds: 0
    property string uptimeText: "…"
    property bool haveSystemMonitor: false

    /* break timer state */
    property int remainingSeconds: 0
    property bool showBreakOverlay: false

    FontLoader {
        id: lorenzoSans
        source: "../fonts/BitcountRegular.ttf"
    }

    /* -------------------------
       Helpers / safe getters
       ------------------------- */
    function getBreakIntervalMinutes() {
        var mins = 20; // default fallback
        if (plasmoid && plasmoid.configuration && plasmoid.configuration.breakInterval !== undefined && plasmoid.configuration.breakInterval !== null) {
            var c = Number(plasmoid.configuration.breakInterval);
            if (!isNaN(c) && c > 0) mins = Math.floor(c);
        }
        return Math.max(1, mins);
    }

    function getBgColor() {
        if (plasmoid && plasmoid.configuration && plasmoid.configuration.backgroundColor) return plasmoid.configuration.backgroundColor;
        return "#ffffff";
    }
    function getTextColor() {
        if (plasmoid && plasmoid.configuration && plasmoid.configuration.textColor) return plasmoid.configuration.textColor;
        return "#000000";
    }

    function resetBreakTimer() {
        var mins = getBreakIntervalMinutes();
        root.remainingSeconds = mins * 60;
        breakTimer.running = true;
        root.showBreakOverlay = false;
    }

    /* -------------------------
       1) System monitor dataengine
       ------------------------- */
    Plasma5Support.DataSource {
        id: sysmon
        engine: "systemmonitor"
        connectedSources: ["system/uptime"]
        interval: 60000

        onDataChanged: {
            var n = Logic.extractUptime(sysmon.data)
            if (n !== null) {
                root.uptimeSeconds = n
                root.uptimeText = Logic.formatUptime(n)
                root.haveSystemMonitor = true
            }
        }
    }

    /* -------------------------
       2) Fallback: /proc/uptime
       ------------------------- */
    Plasma5Support.DataSource {
        id: executor
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            if (!data) return
            var secs = Logic.parseProcUptime(data["stdout"])
            if (secs !== null) {
                root.uptimeSeconds = secs
                root.uptimeText = Logic.formatUptime(secs)
            }
            executor.disconnectSource(sourceName)
        }

        function execCmd(cmd) {
            executor.connectSource(cmd)
        }
    }

    /* fallback timer (initial uptime read) */
    Timer {
        id: fallbackTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (!root.haveSystemMonitor) {
                executor.execCmd("/bin/cat /proc/uptime")
            }
        }
    }

    /* break timer: ticks every second */
    Timer {
        id: breakTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds--
            } else {
                // Stop the timer while overlay is visible to avoid repeated triggers
                breakTimer.running = false
                root.showBreakOverlay = true
                overlayTimer.start()
            }
        }
    }

    /* overlay stays visible for a short while, then reset and restart timer */
    Timer {
        id: overlayTimer
        interval: 5000
        repeat: false
        onTriggered: {
            // fade-out handled by animation; set flag to false after a tiny delay so animation runs
            root.showBreakOverlay = false
            resetBreakTimer()
        }
    }

    Component.onCompleted: {
        fallbackTimer.start()
        resetBreakTimer()
    }

    // when user updates config in Plasma Settings, reset timer to new value
    Connections {
        target: plasmoid.configuration
        onBreakIntervalChanged: resetBreakTimer()
        onBackgroundColorChanged: {} // getters will pick up new color
        onTextColorChanged: {}
    }

    /* -------------------------
       UI (responsive & modern)
       ------------------------- */
    Rectangle {
        id: card
        anchors.fill: parent
        radius: height/2
       

        // modest shadow using a backing rectangle for compatibility
        Rectangle {
            anchors {
                left: card.left
                right: card.right
                top: card.top
                bottom: card.bottom
            }
            z: -1
            color: Qt.rgba(0,0,0,0.0) // invisible; kept for layering compatibility
        }

       GridLayout {
    id: grid
    anchors.fill: parent
    anchors.margins: 24
    columns: 2
    columnSpacing: 12
    rowSpacing: 6

    // Left: uptime
    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
        Layout.fillWidth: true
        Layout.preferredWidth: 2     // take about 2 parts of space
        Layout.leftMargin: 12        // add extra breathing room on the left
        spacing: 4

        Text {
            text: "Screen Time"
            font.family: lorenzoSans.name
            font.pixelSize: 16
            font.bold: true
            color: getTextColor()
        }
        Text {
            text: root.uptimeText
            font.family: lorenzoSans.name
            font.pixelSize: 20
            color: getTextColor()
            opacity: 0.8
        }
    }

    // Right: countdown + progress
    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        Layout.fillWidth: true
        Layout.preferredWidth: 1     // take about 1 part of space (narrower)
        Layout.rightMargin: 12       // keep balance with left margin
        spacing: 6

        Text {
            id: countdown
            text: Logic.formatCountdown(root.remainingSeconds)
            font.family: lorenzoSans.name
            font.pixelSize: 18
            font.bold: true
            color: getTextColor()
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 10
            radius: 6
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
                radius: 6
                gradient: Gradient {
                    GradientStop { position: 0.0; color: getTextColor() }
                    GradientStop { position: 1.0; color: Qt.lighter(getTextColor(), 1.2) }
                }
                opacity: 0.18

                Behavior on width {
                    NumberAnimation { duration: 450; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}


        /* Break overlay: smooth fade in/out */
        Rectangle {
            id: overlay
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            visible: root.showBreakOverlay || overlay.opacity > 0
            opacity: root.showBreakOverlay ? 1 : 0
            z: 10
            radius: card.radius

            Behavior on opacity { NumberAnimation { duration: 300 } }

            Column {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: "⏳ Time's up!"
                    font.pixelSize: 20
                    font.bold: true
                    color: "white"
                }
                Text {
                    text: "Take a short break."
                    color: "white"
                }
            }
        }
    }
}
