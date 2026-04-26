import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    width: 300
    height: 110
    visible: true

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: Math.min(parent.width, parent.height) * 0.05
        color: "white"
        
        GridLayout {
            id: grid
            anchors.fill: parent
            anchors.margins: Math.min(parent.width, parent.height) * 0.05
            
            columns: card.width >= card.height ? 2 : 1

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "Screen Time"
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 4
                    font.pixelSize: 72
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignBottom
                    Rectangle { anchors.fill: parent; color: "red"; opacity: 0.2; z: -1 }
                }
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "00:00"
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 4
                    font.pixelSize: 72
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    Rectangle { anchors.fill: parent; color: "blue"; opacity: 0.2; z: -1 }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "20:00"
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 4
                    font.pixelSize: 72
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Rectangle { anchors.fill: parent; color: "green"; opacity: 0.2; z: -1 }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    Layout.maximumHeight: 20
                    Layout.alignment: Qt.AlignVCenter
                    color: "gray"
                }
            }
        }
    }
}
