import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

TextField {
    id: control
    topInset: 6
    bottomInset: 6
    placeholderText: qsTr("Search")
    bottomPadding: 8
    rightPadding: 5 + clearButton.width
    leftPadding: 5 + searchButton.width
    verticalAlignment: Text.AlignVCenter

    signal search
    signal clear

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: control.Material.buttonHeight
        color: control.Material.rippleColor
    }
    RoundButton {
        id: searchButton
        anchors.left: parent.left
        flat: true
        rightInset: 0
        leftInset: 0
        radius: 0
        icon {
            width: 14
            height: 14
            name: "search"
        }
        onClicked: search()
    }
    RoundButton {
        id: clearButton
        anchors.right: parent.right
        flat: true
        leftInset: 0
        rightInset: 0
        radius: 0
        icon {
            width: 12
            height: 12
            name: "clear-text"
        }
        onClicked: clear()
        visible: control.text
    }
}
