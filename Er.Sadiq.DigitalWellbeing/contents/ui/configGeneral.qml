import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_breakInterval: intervalField.value
    property alias cfg_backgroundColor: bgField.text
    property alias cfg_textColor: textColField.text

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        SpinBox {
            id: intervalField
            Kirigami.FormData.label: i18n("Break interval (minutes):")
            from: 1
            to: 240
        }

        TextField {
            id: bgField
            Kirigami.FormData.label: i18n("Background color (Hex):")
            placeholderText: "#ffffff"
        }

        TextField {
            id: textColField
            Kirigami.FormData.label: i18n("Text color (Hex):")
            placeholderText: "#000000"
        }
    }
}
