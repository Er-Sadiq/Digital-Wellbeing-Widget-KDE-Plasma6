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

    // ----------------------------------------------------
    // Environment Detection & Sizing
    // ----------------------------------------------------
    property bool isHorizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    property bool isVerticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool isDesktop: !isHorizontalPanel && !isVerticalPanel

    Layout.minimumWidth: isHorizontalPanel ? 100 : (isVerticalPanel ? 24 : 120)
    Layout.minimumHeight: isHorizontalPanel ? 24 : (isVerticalPanel ? 100 : 44)
    Layout.preferredWidth: isHorizontalPanel ? 250 : (isVerticalPanel ? 48 : 300)
    Layout.preferredHeight: isHorizontalPanel ? 48 : (isVerticalPanel ? 250 : 110)

    /* ====================================================
     *       1. DESKTOP (PLANAR) UI
     * ==================================================== */
    Rectangle {
        id: desktopCard
        visible: isDesktop
        anchors.fill: parent
        anchors.margins: Math.min(parent.width, parent.height) * 0.05
        color: getBgColor()
        clip: true
        radius: Math.min(height / 2, width * 0.25)

        GridLayout {
            anchors.fill: parent
            anchors.margins: Math.min(parent.width, parent.height) * 0.08
            columns: desktopCard.width >= desktopCard.height * 1.2 ? 2 : 1
            rowSpacing: Math.max(4, desktopCard.height * 0.04)
            columnSpacing: Math.max(4, desktopCard.width * 0.04)

            property real baseFontSize: Math.min(desktopCard.width, desktopCard.height) * (columns === 1 ? 0.14 : 0.20)

            // Left Block: Screen Time
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                    anchors.centerIn: parent
                    spacing: Math.max(2, desktopCard.height * 0.02)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Screen Time"
                        font.family: lorenzoSans.name
                        font.pixelSize: Math.max(8, parent.parent.baseFontSize * 0.7)
                        font.bold: true
                        color: getTextColor()
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.uptimeText
                        font.family: lorenzoSans.name
                        font.pixelSize: Math.max(8, parent.parent.baseFontSize)
                        color: getTextColor()
                        opacity: 0.85
                    }
                }
            }

            // Right Block: Countdown & Progress
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.9, 250)
                    spacing: Math.max(4, desktopCard.height * 0.03)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Logic.formatCountdown(root.remainingSeconds)
                        font.family: lorenzoSans.name
                        font.pixelSize: Math.max(8, parent.parent.baseFontSize)
                        font.bold: true
                        color: getTextColor()
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: Math.max(4, parent.parent.baseFontSize * 0.3)
                        radius: height / 2
                        color: Qt.lighter(getBgColor(), 1.08)
                        border.width: 0

                        Rectangle {
                            anchors.left: parent.left
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
                            opacity: 0.25
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                        }
                    }
                }
            }
        }
    }

    /* ====================================================
     *       2. HORIZONTAL PANEL UI (Taskbar)
     * ==================================================== */
    RowLayout {
        id: horizontalPanel
        visible: isHorizontalPanel
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.uptimeText
            font.family: PlasmaCore.Theme.defaultFont.family
            font.pixelSize: Math.max(10, parent.height * 0.5)
            color: getTextColor()
            opacity: 0.9
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: Math.max(4, parent.height * 0.25)
            radius: height / 2
            color: Qt.lighter(getBgColor(), 1.08)

            Rectangle {
                anchors.left: parent.left
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
                opacity: 0.3
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Logic.formatCountdown(root.remainingSeconds)
            font.family: PlasmaCore.Theme.defaultFont.family
            font.pixelSize: Math.max(10, parent.height * 0.5)
            font.bold: true
            color: getTextColor()
        }
    }

    /* ====================================================
     *       3. VERTICAL PANEL UI (Side Taskbar)
     * ==================================================== */
    ColumnLayout {
        id: verticalPanel
        visible: isVerticalPanel
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.uptimeText
            font.family: PlasmaCore.Theme.defaultFont.family
            font.pixelSize: Math.max(10, parent.width * 0.35)
            color: getTextColor()
            opacity: 0.9
            rotation: -90
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.max(4, parent.width * 0.25)
            radius: width / 2
            color: Qt.lighter(getBgColor(), 1.08)

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: {
                    var total = Math.max(1, getBreakIntervalMinutes() * 60)
                    var frac = (total - root.remainingSeconds) / total
                    return parent.height * Math.max(0, Math.min(1, frac))
                }
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: getTextColor() }
                    GradientStop { position: 1.0; color: Qt.lighter(getTextColor(), 1.2) }
                }
                opacity: 0.3
                Behavior on height { NumberAnimation { duration: 300 } }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Logic.formatCountdown(root.remainingSeconds)
            font.family: PlasmaCore.Theme.defaultFont.family
            font.pixelSize: Math.max(10, parent.width * 0.35)
            font.bold: true
            color: getTextColor()
            rotation: -90
        }
    }

    /* ====================================================
     *       BREAK OVERLAY (Applies everywhere)
     * ==================================================== */
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)
        visible: root.showBreakOverlay || opacity > 0
        opacity: root.showBreakOverlay ? 1 : 0
        z: 10
        radius: isDesktop ? desktopCard.radius : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Math.max(2, Math.min(parent.width, parent.height) * 0.05)
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "⏳ Time's up!"
                font.pixelSize: Math.max(12, Math.min(parent.parent.width, parent.parent.height) * 0.2)
                font.bold: true
                color: "white"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Take a short break."
                font.pixelSize: Math.max(10, Math.min(parent.parent.width, parent.parent.height) * 0.15)
                color: "white"
                visible: isDesktop // Only show subtitle if on desktop to save space
            }
        }
    }
}
