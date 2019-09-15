import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

ColumnLayout {
    id: root
    property alias text: errorLabel.text

    signal reload
    signal back

    LottieAnimation {
        source: Qt.resolvedUrl("../media/lottie/no-internet-connection.json")
        loops: Animation.Infinite
        fillMode: Image.PreserveAspectFit
        running: root.visible
        Layout.alignment: Qt.AlignCenter
        Layout.preferredHeight: 200
        Layout.preferredWidth: 200
    }
    Label {
        id: errorLabel
        horizontalAlignment: Text.AlignHCenter
    }
    RowLayout {
        Layout.alignment: Qt.AlignCenter

        Button {
            id: reloadButton
            flat: true
            checkable: false
            text: qsTr("Reload")
            onClicked: reload()
            Layout.alignment: Qt.AlignHCenter
            Material.background: root.Material.rippleColor
            Material.elevation: 0
        }
        Button {
            id: backButton
            flat: true
            text: qsTr("Back")
            onClicked: back()
            Layout.alignment: Qt.AlignHCenter
            Material.background: root.Material.rippleColor
            Material.elevation: 0
        }
    }
}
