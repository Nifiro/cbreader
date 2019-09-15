import QtQuick 2.12
import QtQuick.Controls.Material 2.12

Rectangle {
    property real bgOpacity: 0.1
    readonly property color backgroundColor: Qt.rgba(Material.theme * 255,
                                                     Material.theme * 255,
                                                     Material.theme * 255,
                                                     bgOpacity)

    radius: 4;
    color: backgroundColor
}
