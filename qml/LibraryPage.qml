import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12

import Qt.labs.platform 1.1 as Platform

import com.cbreader.models 1.0
import Document 1.0

Page {
    id: root
    clip: true
    padding: 0
    leftPadding: (width - grid.cellWidth * Math.floor(width / grid.cellWidth)) / 2

    Component.onCompleted: LibraryModel.loadModel()

    function addManga() {
        inputDialog.open();
    }

    GridView {
        id: grid
        anchors.fill: parent

        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.AutoFlickIfNeeded
        cellWidth: 222
        cellHeight: 350
        model: LibraryModel
        delegate: mangaDelegate

        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                easing.type: Easing.InOutQuad
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                easing.type: Easing.InOutQuad
            }
        }

        ScrollBar.vertical: ScrollBar { id: scrollBar }

        Component {
            id: mangaDelegate

            Pane {
                id: pane
                height: GridView.view.cellHeight
                width: GridView.view.cellWidth
                leftInset: 5
                rightInset: 5
                topInset: 5
                bottomInset: 5
                focusPolicy: Qt.TabFocus
                background: ThemedRectangle { bgOpacity: 0.2 }

                Menu {
                    id: contextMenu

                    MenuItem {
                        icon.name: "delete-manga"
                        text: qsTr("Delete")
                        onClicked: LibraryModel.remove(index)
                    }
                }

                ColumnLayout {
                    anchors.fill: parent

                    Image {
                        id: coverImage
                        asynchronous: true
                        source: model.image
                        sourceSize.width: pane.availableWidth
                        sourceSize.height: pane.availableHeight

                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: pane.background.bgOpacity = 0.3
                            onExited: pane.background.bgOpacity = 0.2
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: {
                                if (mouse.button === Qt.RightButton)
                                    contextMenu.popup();
                                else {
                                    SharedData.path = model.path;
                                    SharedData.mangaIndex = index;
                                    SharedData.readOnline = false;
                                    SharedData.open();
                                }
                            }
                        }
                    }
                    Label {
                        id: titleLabel
                        elide: Text.ElideRight
                        text: model.title
                        Layout.fillWidth: true
                    }
                    Label {
                        id: authorLabel
                        elide: Text.ElideRight
                        text: model.author
                        Layout.fillWidth: true
                    }
                    ProgressBar {
                        id: progress
                        value: model.readPages / model.pages
                        Layout.fillWidth: true

                        ToolTip.visible: hovered
                        ToolTip.text: model.readPages + "/" + model.pages
                    }
                }
            }
        }
    }

    Dialog {
        id: messageDialog

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        parent: Overlay.overlay
        modal: true
        standardButtons: Dialog.Ok

        title: qsTr("Error")

        Label {
            text: qsTr("Unknown ComicBook format")
        }
    }

    Dialog {
        id: inputDialog

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.max(parent.width / 3, 250)
        parent: Overlay.overlay

        property url file

        modal: true
        title: qsTr("Add manga")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (Document.open(file, Document.Append))
                LibraryModel.append(
                            Document.firstPagePath(),
                            Document.path(),
                            titleField.text,
                            authorField.text,
                            Document.pages())
            else {
                messageDialog.open()
            }
        }

        ColumnLayout {
            anchors.fill: parent

            Label {
                elide: Label.ElideRight
                text: qsTr("Please provide information:")
                Layout.fillWidth: true
            }
            TextField {
                id: titleField
                placeholderText: qsTr("Title")
                Layout.fillWidth: true
            }
            TextField {
                id: authorField
                placeholderText: qsTr("Author")
                Layout.fillWidth: true
            }
            RowLayout {
                Button {
                    id: addMangaButton
                    flat: true
                    text: qsTr("Choose a file")
                    onClicked: fileDialog.open()
                    Layout.fillWidth: true
                }
                Button {
                    id: addDirButton
                    flat: true
                    text: qsTr("Open directory")
                    onClicked: folderDialog.open()
                    Layout.fillWidth: true
                }
            }
            Label {
                id: fileLabel
                text: SharedData.baseName(inputDialog.file)
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
            }
        }
    }

    Platform.FileDialog {
        id: fileDialog
        fileMode: Platform.FileDialog.OpenFile
        selectedNameFilter.index: 0
        nameFilters: ["Comic Book Archive (*.cbz *.cbr)", "All files (*.*)"]
        onAccepted: inputDialog.file = file
    }

    Platform.FolderDialog {
        id: folderDialog
        onAccepted: inputDialog.file = folder
    }
}
