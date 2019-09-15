import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

Rectangle {
    property alias text: infoText.text

    color: Material.color(Material.Indigo)
    height: Material.buttonHeight
    width: 60
    visible: SharedData.pages != 0

    Label {
        id: infoText
        anchors.centerIn: parent
    }
}
