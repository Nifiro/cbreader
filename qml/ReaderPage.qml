import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import Qt.labs.platform 1.1 as Platform
import Qt.labs.settings 1.1

import com.cbreader.models 1.0
import Document 1.0
import ClipboardProxy 1.0

Page {
    id: root
    clip: true

    property real scaleFactor: 1.0
    property int flipDirection: 0

    states: [
        State {
            name: ""
            PropertyChanges {
                target: flickable
                visible: true
            }
            PropertyChanges {
                target: thumbnailsLoader
                active: false
            }
        },
        State {
            name: "PREVIEW"
            PropertyChanges {
                target: flickable
                visible: false
            }
            PropertyChanges {
                target: thumbnailsLoader
                active: true
            }
        }
    ]

    header: ToolBar {
        leftPadding: 8
        font.pixelSize: 16
        font.family: "Material Icons"
        visible: !SharedData.fullscreen
        Material.foreground: "white"

        Flow {
            anchors.fill: parent

            Row {
                ToolButton {
                    text: "\ue2c8"
                    onClicked: open()

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Open")
                }
                ToolButton {
                    text: "\ue5d5"
                    onClicked: {
                        if (SharedData.mangaIndex != -1) {
                            flipDirection = -1;
                            SharedData.page =
                                    LibraryModel.data(
                                        LibraryModel.index(SharedData.mangaIndex, 0),
                                        LibraryModel.ReadPagesRole)
                        }
                    }

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Resume")
                }
                ToolButton {
                    text: "\ue161"
                    onClicked: saveToFile()

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Save to file")
                }
                ToolButton {
                    text: "\ue8e2"
                    onClicked: translation.open()

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Translate")
                }
                ToolSeparator {}
            }

            Row {
                ToolButton {
                    text: "\ue5dc"

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("First page")
                    onClicked: firstPage()
                }
                ToolButton {
                    text: "\ue5c4"

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Previous page")
                    onClicked: prevPage()
                }
                ToolButton {
                    text: "\ue5c8"

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Next page")
                    onClicked: nextPage()
                }
                ToolButton {
                    text: "\ue5dd"

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Last page")
                    onClicked: lastPage()
                }
                ToolSeparator {}
            }

            Row {
                ToolButton {
                    text: "\ue5d0"
                    onClicked: SharedData.fullscreen = true

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Fullscreen")
                }
                ToolButton {
                    text: "\ue85b"
                    onClicked: fitWidth()

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Fit width")
                }
                ToolButton {
                    text: "\ue41a"
                    onClicked: mangaPage.rotation += 90

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Rotate right")
                }
                ToolButton {
                    text: "\ue419"
                    onClicked: mangaPage.rotation -= 90

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Rotate left")
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+O"
        context: Qt.ApplicationShortcut
        onActivated: open()
    }
    Shortcut {
        sequence: "Enter"
        onActivated: fitWidth()
    }
    Shortcut {
        sequence: "Right"
        onActivated: nextPage()
    }
    Shortcut {
        sequence: "Left"
        onActivated: prevPage()
    }
    Shortcut {
        sequence: "Up"
        onActivated: verticalScroll.decrease();
    }
    Shortcut {
        sequence: "Down"
        onActivated: verticalScroll.increase();
    }
    Shortcut {
        sequence: "+"
        onActivated: scaleFactor = Math.min(3, scaleFactor + 0.1)
    }
    Shortcut {
        sequence: "-"
        onActivated: scaleFactor = Math.max(0.3, scaleFactor - 0.1)
    }
    Shortcut {
        sequence: "Escape"
        onActivated: SharedData.fullscreen = false
    }
    Shortcut {
        sequence: "F"
        onActivated: SharedData.fullscreen = !SharedData.fullscreen
    }

    function openManga() {
        mangaPage.source = "";
        mangaPage.scale = 0.9;
        root.state = "";
        if (SharedData.readOnline) {
            mangaPage.source = "https://cdn.mangaeden.com/mangasimg/" + SharedData.images[0];
        } else if (Document.open(SharedData.path, Document.Read)) {
            SharedData.pages = Document.pages();
            if (!Document.isDirectory()) {
                mangaPage.source = "image://archive/" + 0;
                SharedData.images = SharedData.pages;
            } else {
                SharedData.images = Document.entries();
                mangaPage.source = Document.path() + SharedData.images[0];
            }
        }
        scaleFactor = 1.0;
        SharedData.page = 1;
        SharedData.opened = true;
        SharedData.ready();
    }

    function setImageSource() {
        if (SharedData.readOnline)
            mangaPage.source = "https://cdn.mangaeden.com/mangasimg/" + SharedData.images[SharedData.page - 1];
        else {
            if (!Document.isDirectory())
                mangaPage.source = "image://archive/" + (SharedData.page - 1);
            else
                mangaPage.source = Document.path() + SharedData.images[SharedData.page - 1];
        }
        if (SharedData.mangaIndex != -1) {
            var idx = LibraryModel.index(SharedData.mangaIndex, 0);
            var readPages = LibraryModel.data(idx, LibraryModel.ReadPagesRole);
            if (SharedData.page > readPages)
                LibraryModel.setData(idx, SharedData.page, LibraryModel.ReadPagesRole);
        }
    }

    function open() {
        openDialog.open();
    }

    function saveToFile() {
        saveDialog.open();
    }

    function resumeLastFile() {
        SharedData.path = SharedData.lastFile;
        SharedData.mangaIndex = -1;
        SharedData.readOnline = false;
        SharedData.open();
    }

    function grabPageToFile(path) {
        mangaPage.grabToImage(function(result) {
            result.saveToFile(path.toString().substr(8));
        });
    }

    function saveToClipboard() {
        mangaPage.grabToImage(function(result) {
            ClipboardProxy.setImage(result.image);
        });
    }

    function fitWidth() {
        scaleFactor = flickable.width / mangaPage.sourceSize.width;
    }

    function firstPage() {
        flipDirection = 1;
        SharedData.page = 1;
    }

    Loader {
        id: settingsLoader

        sourceComponent: Settings {
            category: SharedData.currentMangaId
        }
    }

    function prevPage() {
        flipDirection = 1;
        if (SharedData.readOnline && SharedData.page == 1
                && SharedData.chapterIndex + 1 < SharedData.chapters.length) {
            var chapterId = SharedData.chapters[SharedData.chapterIndex + 1][3];
            settingsLoader.item.setValue(chapterId, true);
            SharedData.chapterIndex++;
            SharedData.loadChapterDetails(chapterId);
        }
        else
            SharedData.page = Math.max(1, SharedData.page - 1);
    }

    function nextPage() {
        flipDirection = -1;
        if (SharedData.readOnline && SharedData.page == SharedData.pages
                && SharedData.chapterIndex - 1 >= 0) {
            var chapterId = SharedData.chapters[SharedData.chapterIndex - 1][3];
            settingsLoader.item.setValue(chapterId, true);
            SharedData.chapterIndex--;
            SharedData.loadChapterDetails(chapterId);
        }
        else
            SharedData.page = Math.min(SharedData.pages, SharedData.page + 1);
    }

    function lastPage() {
        flipDirection = -1;
        SharedData.page = SharedData.pages;
    }

    ProgressBar {
        anchors.top: parent.top
        value: mangaPage.progress
        visible: SharedData.readOnline && mangaPage.status == Image.Loading
        width: parent.width
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: mangaPage.width
        contentHeight: mangaPage.height
        leftMargin: Math.max(0, (width - mangaPage.width) / 2)

        Image {
            id: mangaPage
            asynchronous: true
            scale: 0.9
            mipmap: sourceSize.width > Screen.width
            width: sourceSize.width * scaleFactor
            height: sourceSize.height * scaleFactor
            onStatusChanged: {
                if (status == Image.Ready)
                    flipBackAnimation.start()
            }

            Behavior on rotation {
                RotationAnimation {
                    duration: 450
                    easing.type: Easing.InOutQuad
                }
            }
            Behavior on width {
                NumberAnimation {}
            }
            Behavior on height {
                NumberAnimation {}
            }

            SequentialAnimation {
                id: pageFlipAnimation
                running: false
                onFinished: setImageSource()

                ScaleAnimator {
                    target: mangaPage
                    from: 1.0
                    to: 0.9
                    easing.type: Easing.InOutQuad
                }
                XAnimator {
                    target: mangaPage
                    to: flipDirection * (mangaPage.width + flickable.leftMargin)
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                id: flipBackAnimation
                alwaysRunToEnd: true
                running: false

                XAnimator {
                    target: mangaPage
                    from: -flipDirection * (mangaPage.width + flickable.leftMargin)
                    to: 0
                    easing.type: Easing.InOutQuad
                }
                ScaleAnimator {
                    target: mangaPage
                    from: 0.9
                    to: 1.0
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Connections {
            target: SharedData
            onPageChanged: {
                verticalScroll.position = 0;
                pageFlipAnimation.start();
            }
            onOpen: {
                settingsLoader.active = false;
                settingsLoader.active = true;
                openManga();
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: verticalScroll

            Behavior on position {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
        }
        ScrollBar.horizontal: ScrollBar {}
    }

    Loader {
        id: thumbnailsLoader
        anchors.fill: parent
        active: false
        sourceComponent: thumbnailsGrid
    }

    Component {
        id: thumbnailsGrid

        GridView {
            clip: true
            cellWidth: 222
            cellHeight: 350
            currentIndex: SharedData.page - 1
            boundsBehavior: Flickable.StopAtBounds
            model: SharedData.images
            leftMargin: (root.width - cellWidth * Math.floor(root.width / cellWidth)) / 2
            highlight: Pane {
                topInset: 3
                bottomInset: 3
                leftInset: 3
                rightInset: 3
                background: Rectangle {
                    border {
                        width: 2
                        color: root.Material.accentColor
                    }
                    color: "transparent"
                }
            }

            ScrollBar.vertical: ScrollBar {}

            delegate: Pane {
                leftInset: 5
                rightInset: 5
                topInset: 5
                bottomInset: 5
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight
                background: Rectangle { color: root.Material.rippleColor }

                Image {
                    asynchronous: true
                    mipmap: true
                    sourceSize {
                        width: parent.width
                        height: parent.height - (pageLabel.height + 5)
                    }
                    source: sourcePath(index)
                }
                Label {
                    id: pageLabel
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                    text: index + 1
                }
                TapHandler {
                    onTapped: {
                        root.state = "";
                        flipDirection = SharedData.page > (index + 1) ? 1 : -1;
                        SharedData.page = index + 1;
                    }
                }

                function sourcePath(index) {
                    if (SharedData.readOnline)
                        return "https://cdn.mangaeden.com/mangasimg/" + SharedData.images[index];
                    else {
                        if (!Document.isDirectory()) {
                            return "image://archive/" + index;
                        }
                        else
                            return Document.path() + SharedData.images[index];
                    }
                }
            }
        }
    }

    TranslationPopup {
        id: translation
        height: 200
        width: 300
    }

    Button {
        x: scaleLabel.x - width - 1
        y: scaleLabel.y - topInset
        background: Rectangle {
            implicitWidth: 60
            implicitHeight: root.Material.buttonHeight
            color: root.Material.color(root.Material.Indigo)
        }
        icon.name: "thumbnails"
        onClicked: root.state = root.state == "" ? "PREVIEW" : ""
        visible: SharedData.pages
    }

    LabeledRect {
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        text: SharedData.page + "/" + SharedData.pages
    }

    LabeledRect {
        id: scaleLabel
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        text: Math.floor(scaleFactor * 100) + "%"
    }

    Platform.FileDialog {
        id: openDialog
        fileMode: Platform.FileDialog.OpenFile
        selectedNameFilter.index: 1
        nameFilters: ["Comic Book Archive (*.cbz *.cbr)", "All files (*.*)"]
        onAccepted: {
            SharedData.path = file;
            SharedData.readOnline = false;
            SharedData.addRecent(file);
            SharedData.mangaIndex = -1;
            openManga();
        }
    }

    Platform.FileDialog {
        id: saveDialog
        currentFile: SharedData.baseName(mangaPage.source)
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["Image files (*.png *.jpg)"]
        onAccepted: grabPageToFile(file)
    }
}
