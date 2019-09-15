import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

TextField {
    id: control
    topInset: 6
    bottomInset: 6
    placeholderText: qsTr("Search")
    bottomPadding: 8
    leftPadding: 12
    rightPadding: 12
    verticalAlignment: Text.AlignVCenter

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: control.Material.buttonHeight
        color: control.Material.rippleColor
    }
}
