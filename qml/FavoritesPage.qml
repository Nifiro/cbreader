import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import com.cbreader.models 1.0

Page {
    id: root
    clip: true
    padding: 0
    leftPadding: (root.StackView.view.width - grid.cellWidth *
                  Math.floor(root.StackView.view.width / grid.cellWidth)) / 2

    header: ToolBar {
        horizontalPadding: 8
        verticalPadding: 0
        width: parent.width
        Material.background: root.Material.dialogColor
        Material.foreground: root.Material.primaryTextColor

        RowLayout {
            anchors.fill: parent

            Label {
                text: FavoritesModel.total + qsTr(" manga")
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            ComboBox {
                property var sortRoles: ["addedAt", "title"]
                flat: true
                model: [qsTr("Date Added"), qsTr("Name")]
                displayText: qsTr("Sort by: ") + currentText
                onCurrentIndexChanged: proxyModel.sortRoleName = sortRoles[currentIndex]
                Layout.preferredWidth: fontMetrics.advanceWidth(qsTr("Sort by: ") + spacing + leftPadding +
                                                                model[2]) + rightPadding
            }
            Button {
                flat: true
                implicitWidth: 40
                icon.name: "arrow-downward"
                onClicked: {
                    proxyModel.ascendingSortOrder = !proxyModel.ascendingSortOrder;
                    rotation = (rotation + 180) % 360;
                }

                Behavior on rotation {
                    RotationAnimator {
                        duration: 1000
                        easing.type: Easing.OutElastic
                    }
                }
            }
            RoundButton {
                id: syncButton
                flat: true
                icon.name: "sync"
                onClicked: FavoritesModel.synchronize();

                RotationAnimation {
                    target: syncButton
                    alwaysRunToEnd: true
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: FavoritesModel.status == FavoritesModel.Syncing
                }
            }
        }
    }

    states: [
        State {
            name: "Ready"
            when: FavoritesModel.status == FavoritesModel.Ready ||
                  FavoritesModel.status == FavoritesModel.Syncing
            PropertyChanges {
                target: grid
                visible: true
            }
        }
    ]

    SortFilterProxyModel {
        id: proxyModel
        sortRoleName: "title"
        sourceModel: FavoritesModel
        sortCaseSensitivity: Qt.CaseInsensitive
        filterRoleName: "title"
        filterCaseSensitivity: Qt.CaseInsensitive
    }

    FontMetrics {
        id: fontMetrics
        font.family: parent.font.family
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: FavoritesModel.status == FavoritesModel.Loading
    }

    GridView {
        id: grid
        anchors.fill: parent
        clip: true
        cellWidth: 222
        cellHeight: 350
        model: proxyModel
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.AutoFlickIfNeeded
        delegate: favoritesDelegate
        visible: false

        ScrollBar.vertical: ScrollBar { id: scrollBar }

        Component {
            id: favoritesDelegate

            Pane {
                id: delegateRoot
                leftInset: 5
                rightInset: 5
                topInset: 5
                bottomInset: 5
                background: ThemedRectangle { id: bgRect; bgOpacity: 0.2 }
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                ColumnLayout {
                    anchors.fill: parent

                    EmptyCover {
                        visible: !model.image
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                    Image {
                        id: coverImage
                        source: model.image
                        sourceSize.width: delegateRoot.availableWidth
                        sourceSize.height: delegateRoot.availableHeight
                        visible: model.image

                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumHeight: 266
                    }
                    Item {
                        visible: model.image && coverImage.height < 266
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                    Label {
                        elide: Text.ElideRight
                        text: model.title
                        Layout.fillWidth: true
                    }
                    Label {
                        elide: Text.ElideRight
                        text: model.author
                        Layout.fillWidth: true
                    }
                    Label {
                        elide: Text.ElideRight
                        text: model.totalChapters + qsTr(" chapters")
                        Layout.fillWidth: true
                    }
                }

                Loader {
                    active: model.newChapters > 0
                    anchors {
                        right: parent.right
//                        top: parent.top
                        bottom: parent.bottom
                    }
                    sourceComponent: Rectangle {
                        border {
                            width: 1
                            color: Material.color(Material.Teal, Material.ShadeA200)
                        }
                        width: Material.buttonHeight
                        height: Material.buttonHeight
                        color: Material.color(Material.Teal)
                        radius: width / 2
                        visible: model.newChapters > 0 && FavoritesModel.status != FavoritesModel.Syncing

                        Label {
                            anchors.centerIn: parent
                            text: model.newChapters
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.StackView.view.push("MangaDetail.qml",
                                                 {
                                                     "mangaId": model.id,
                                                     "newChapters": model.newChapters,
                                                     "pageIndex": 2
                                                 });
                        model.totalChapters += model.newChapters;
                        model.newChapters = 0;
                    }
                    onEntered: bgRect.bgOpacity = 0.3
                    onExited: bgRect.bgOpacity = 0.2
                }
            }
        }
    }
}
