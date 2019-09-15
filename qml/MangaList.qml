import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import com.cbreader.models 1.0

Page {
    id: root

    property var displayRoles: [MangaModel.HitsRole, MangaModel.TitleRole, MangaModel.YearRole]
    property int sortIndex

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

        CategoriesPopup {
            id: genresPopup
            x: filterButton.x - width / 2
            y: filterButton.y + filterButton.height
        }
        RowLayout {
            anchors.fill: parent

            Label {
                text: MangaModel.total + qsTr(" manga")
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            ToolSeparator {}
            SearchField {
                id: searchText
                onAccepted: proxyModel.filterPattern = text
                onSearch: proxyModel.filterPattern = text
                onClear: {
                    text = "";
                    proxyModel.filterPattern = text;
                    grid.currentIndex = -1;
                }
            }
            Button {
                id: filterButton
                flat: true
                implicitWidth: 40
                icon.name: "filter"
                onClicked: genresPopup.open()
            }
            ToolSeparator {}
            ComboBox {
                id: sortSelection

                property var sortRoles: ["hits", "title", "lastChapterDate"]

                flat: true
                model: [qsTr("Rank"), qsTr("Name"), qsTr("Last Updated")]
                displayText: qsTr("Sort by: ") + currentText
                onCurrentIndexChanged: {
                    sortIndex = currentIndex;
                    proxyModel.sortRoleName = sortRoles[currentIndex];
                    grid.currentIndex = -1;
                }
                Layout.preferredWidth: fontMetrics.advanceWidth(qsTr("Sort by: ") +
                                                                model[2]) + implicitIndicatorWidth
            }
            Button {
                flat: true
                implicitWidth: 40
                icon.name: "arrow-downward"
                rotation: 180
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
        }
    }

    states: [
        State {
            name: "Loading"
            when: MangaModel.status == MangaModel.Loading
        },
        State {
            name: "Ready"
            when: MangaModel.status == MangaModel.Ready
            PropertyChanges {
                target: grid
                visible: true
            }
        },
        State {
            name: "NoConnection"
            when: MangaModel.status == MangaModel.NoConnection
            PropertyChanges {
                target: networkError
                text: qsTr("No Internet connection\n" +
                           "Check your Internet connection and try again.")
                visible: true
            }
        },
        State {
            name: "Error"
            when: MangaModel.status == MangaModel.Error
            PropertyChanges {
                target: networkError
                text: qsTr("An error occured while loading page:\n") + MangaModel.errorString
                visible: true
            }
        }
    ]

    SortFilterProxyModel {
        id: proxyModel
        filters: RegExpFilter {
            roleName: "categories"
            pattern: SharedData.pattern
        }
        sortRoleName: "hits"
        sourceModel: MangaModel
        ascendingSortOrder: false
        sortCaseSensitivity: Qt.CaseInsensitive
        filterRoleName: "title"
        filterCaseSensitivity: Qt.CaseInsensitive
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: root.state == "Loading"
    }
    NetworkFailure {
        id: networkError
        anchors.centerIn: parent
        visible: false
        onReload: MangaModel.getMangaList()
    }
    FontMetrics {
        id: fontMetrics
        font.family: parent.font.family
    }
    GridView {
        id: grid
        anchors.fill: parent
        currentIndex: -1
        clip: true
        cellWidth: 222
        cellHeight: 350
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        model: proxyModel
        visible: false
        delegate: mangaDelegate

        Component {
            id: mangaDelegate

            Pane {
                id: pane

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
                        source: scrollBar.pressed ? "" : model.image
                        sourceSize.width: pane.availableWidth
                        sourceSize.height: pane.availableHeight
                        visible: model.image

                        Layout.alignment: Qt.AlignTop
                        Layout.maximumWidth: pane.availableWidth
                        Layout.maximumHeight: pane.availableHeight - titleLabel.height -
                                              statusLabel.height - lastUpdatedLabel.height - parent.spacing * 4
                    }
                    Item {
                        visible: model.image
                        Layout.fillHeight: true
                    }
                    Label {
                        id: titleLabel
                        elide: Text.ElideRight
                        text: model.title
                        Layout.fillWidth: true
                    }
                    Label {
                        id: statusLabel
                        elide: Text.ElideRight
                        text: model.status
                        Layout.fillWidth: true
                    }
                    Label {
                        id: lastUpdatedLabel
                        elide: Text.ElideRight
                        text: model.lastUpdated
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.StackView.view.push("MangaDetail.qml",
                                                        {"mangaId": model.id, "pageIndex": 1})
                    onEntered: bgRect.bgOpacity = 0.3
                    onExited: bgRect.bgOpacity = 0.2
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: scrollBar.width + 5
            color: Material.color(Material.Teal)
            radius: 2
            height: Material.buttonHeight
            width: 40
            y: parent.height * (scrollBar.position + scrollBar.size / 2) - height / 2
            visible: scrollBar.pressed

            Label {
                id: indicatorLabel
                anchors.centerIn: parent
            }
        }
        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            minimumSize: 0.01
            onPositionChanged: {
                if (pressed)
                {
                    var row = Math.floor(proxyModel.count * position);
                    if (sortIndex == 0)
                        indicatorLabel.text = row + 1;
                    else {
                        var data = proxyModel.data(proxyModel.index(row, 0), displayRoles[sortIndex])
                        indicatorLabel.text = sortIndex == 1 ? data[0] : data
                    }
                }
            }
        }
    }
}
