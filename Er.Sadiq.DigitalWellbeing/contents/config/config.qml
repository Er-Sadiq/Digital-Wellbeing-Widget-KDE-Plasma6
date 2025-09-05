import QtQuick 6.5
import QtQuick.Controls 6.5
import org.kde.plasma.configuration 2.0

ConfigPage {
    id: page

    ConfigGroup {
        name: "General"

        ConfigInteger {
            name: "breakInterval"
            defaultValue: 20
            label: "Break interval (minutes)"
            minimum: 1
            maximum: 240
        }

        ConfigColor {
            name: "backgroundColor"
            defaultValue: "#ffffff"
            label: "Background color"
        }

        ConfigColor {
            name: "textColor"
            defaultValue: "#000000"
            label: "Text color"
        }
    }
}
