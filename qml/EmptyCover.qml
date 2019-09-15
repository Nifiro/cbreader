import QtQuick 2.12
import QtQuick.Controls.Material 2.12

Rectangle {
    color: "#eeeeee"
    border {
        width: 1
        color: Qt.rgba(Material.theme * 255,
                       Material.theme * 255,
                       Material.theme * 255,
                       0.12)
    }

    Image {
        asynchronous: true
        anchors.centerIn: parent
        source: "../media/images/not_available.svg"
    }
}
