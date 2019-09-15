import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.1
//import Qt.labs.lottieqt 1.0

import com.cbreader.models 1.0
import NetworkManager 1.0
import DownloadManager 1.0
import CacheManager 1.0

Page {
    id: root

    property string mangaId
    property int pageIndex
    property int newChapters;
    property bool favorite
    property var details
    property string lastChapterId;
    //    property string lastReadChapterId
    //    property int lastReadChapterIndex

    property var types: [qsTr("Japanese Manga"), qsTr("Korean Manhwa"),
        qsTr("Chinese Manhua"), qsTr("Comic"), qsTr("Doujinshi")]
    property var statuses: [qsTr("Suspended"), qsTr("Ongoing"), qsTr("Completed")]

    clip: true
    states: [
        State {
            name: "Loading"
        },
        State {
            name: "Ready"
            when: chapters.status == ChaptersModel.Ready
            PropertyChanges {
                target: componentLoader
                sourceComponent: mangaInfo
            }
        },
        State {
            name: "Error"
            PropertyChanges {
                target: networkError
                text: qsTr("An error occured while loading page.")
                visible: true
            }
        },
        State {
            name: "NoConnection"
            PropertyChanges {
                target: networkError
                text: qsTr("No Internet connection\n" +
                           "Check your Internet connection and try again.")
                visible: true
            }
        }
    ]

    function loadMangaDetails() {
        root.state = "Loading";
        favorite = FavoritesModel.contains(mangaId);
        lastChapterId = settingsLoader.item.value("lastChapter", "");
        if (!NetworkManager.online()) {
            if (CacheManager.isCached(mangaId)) {
                details = JSON.parse(CacheManager.loadModel(mangaId));
                chapters.loadModel(details.chapters, mangaId);
            }
            else
                root.state = "NoConnection";
        }
        else {
            var request = new XMLHttpRequest();
            request.onreadystatechange = function() {
                if (request.readyState === XMLHttpRequest.DONE) {
                    if (request.responseText)
                    {
                        details = JSON.parse(request.responseText);
                        chapters.loadModel(details.chapters, mangaId);
                        CacheManager.storeModel(mangaId, request.responseText);
                    }
                    else
                        root.state = "Error";
                }
            }
            request.open("GET", "https://www.mangaeden.com/api/manga/" + mangaId + "/")
            request.send();
        }
    }

    StackView.onActivating: loadMangaDetails()

    Connections {
        target: DownloadManager
        onDownloadProgress: chapters.updateProgress(chapterId, received, total)
        onDownloadFinished: LibraryModel.append(image, path, title, author, pages)
    }
    Connections {
        target: SharedData
        onChapterIndexChanged: {
            settingsLoader.active = false;
            settingsLoader.active = true;
        }
    }
    BusyIndicator {
        anchors.centerIn: parent
        running: root.state == "Loading"
    }
    NetworkFailure {
        id: networkError
        anchors.centerIn: parent
        onReload: loadMangaDetails()
        onBack: root.StackView.view.pop();
        visible: false
    }
    ChaptersModel {
        id: chapters
    }
    Loader {
        id: settingsLoader

        sourceComponent: Settings {
            category: mangaId
            //            property alias lastChapter: root.lastReadChapterId
            //            property alias index: root.lastReadChapterIndex
        }
    }
    Loader {
        id: componentLoader
        anchors.fill: parent
    }
    Component {
        id: mangaInfo

        Flickable {
            contentHeight: page.height
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.AutoFlickIfNeeded

            ScrollIndicator.vertical: ScrollIndicator {}

            Page {
                id: page
                padding: 5
                width: parent.width

                header: ToolBar {
                    //                    Material.background: root.Material.dialogColor
                    Material.foreground: "white"

                    RowLayout {
                        anchors.fill: parent

                        ToolButton {
                            icon.name: "prev-page"
                            onClicked: root.StackView.view.pop()
                        }
                        Label {
                            text: details.title
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter
                        }
                        ToolButton {
                            //  onClicked: {
                            ////      console.log(jsonAnimation.status);
                            //      if (favorite) {
                            ////          jsonAnimation.direction = LottieAnimation.Reverse;
                            ////          jsonAnimation.gotoAndPlay(jsonAnimation.startFrame);
                            //          FavoritesModel.remove(mangaId);
                            //          favorite = false;
                            //      }
                            //      else {
                            ////          jsonAnimation.direction = LottieAnimation.Forward;
                            ////          jsonAnimation.gotoAndPlay(jsonAnimation.startFrame);
                            //          jsonAnimation.running = true;
                            //          FavoritesModel.append(mangaId,
                            //                                details.image
                            //                                ? "image://cover/" + details.image
                            //                                : "",
                            //                                details.title,
                            //                                details.author,
                            //                                details.chapters_len,
                            //                                0);
                            //          favorite = true;
                            //      }
                            //  }

                            ////  LottieAnimation {
                            ////      id: jsonAnimation
                            ////      anchors.fill: parent
                            ////      source: Qt.resolvedUrl("../media/lottie/favorite.json")
                            ////      fillMode: Image.PreserveAspectFit
                            ////  }

                            ////  LottieAnimation {
                            ////      id: jsonAnimation
                            ////      anchors.fill: parent
                            ////      source: "favorite.json"
                            ////      autoPlay: false
                            ////      onStatusChanged: {
                            ////          console.log("status changed. ready?", status == LottieAnimation.Ready);
                            ////          if (status == LottieAnimation.Ready) {
                            ////              if (favorite)
                            ////                  gotoAndPlay(endFrame)
                            ////          }
                            ////      }
                            ////  }
                            icon.name: favorite ? "make-favorite-solid" : "make-favorite-border"

                            Behavior on rotation {
                                RotationAnimator {
                                    duration: 440
                                    easing.type: Easing.InOutQuad
                                }
                            }
                            onClicked: {
                                if (favorite) {
                                    icon.name = "make-favorite-border";
                                    FavoritesModel.remove(mangaId);
                                    favorite = false;
                                }
                                else {
                                    icon.name = "make-favorite-solid";
                                    FavoritesModel.append(mangaId,
                                                          details.image
                                                          ? "image://cover/" + details.image
                                                          : "",
                                                          details.title,
                                                          details.author,
                                                          details.chapters_len,
                                                          0);
                                    favorite = true;
                                }
                                rotation += 360;
                            }
                        }
                    }
                }

                RowLayout {
                    width: parent.width

                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        Layout.minimumWidth: 250

                        Pane {
                            background: ThemedRectangle {}
                            Layout.fillWidth: true

                            ColumnLayout {
                                width: parent.width

                                RowLayout {
                                    Label {
                                        text: qsTr("Description")
                                        font.pixelSize: 24
                                        Layout.fillWidth: true
                                    }
                                    Button {
                                        text: lastChapterId ? qsTr("Resume") : qsTr("Read")
                                        Material.background: Material.color(Material.Indigo)
                                        Material.foreground: "white"
                                        onClicked: {
                                            var chapterId = settingsLoader.item.value("lastChapter");
                                            var chapterIndex = settingsLoader.item.value("index");
                                            SharedData.chapters = details.chapters;
                                            SharedData.currentMangaId = mangaId;
                                            if (!chapterId) {
                                                chapterId = details.chapters[details.chapters_len - 1][3];
                                                chapterIndex = details.chapters_len - 1;
                                                // lastReadChapterId = firstChapterId;
                                                // lastReadChapterIndex = details.chapters_len - 1;
                                            }
                                            SharedData.chapterIndex = chapterIndex;
                                            SharedData.loadChapterDetails(chapterId);
                                        }
                                    }
                                }
                                Label {
                                    text: details.description
                                    textFormat: Text.RichText
                                    horizontalAlignment: Text.AlignJustify
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                Flow {
                                    spacing: 5
                                    Layout.fillWidth: true

                                    Repeater {
                                        model: details.categories
                                        Button {
                                            flat: true
                                            text: modelData
                                            highlighted: SharedData.isGenreSelected(modelData)
                                            onClicked: {
                                                if (pageIndex == 1)
                                                    root.StackView.view.pop()
                                                SharedData.selectGenre(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Pane {
                            background: ThemedRectangle {}
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            ColumnLayout {
                                anchors.fill: parent

                                Label {
                                    id: chaptersLabel
                                    text: details.chapters_len + qsTr(" chapters")
                                    font.pixelSize: 24
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: selectButton.height

                                    Button {
                                        id: markReadButton
                                        flat: true
                                        icon.name: "mark-as-read"
                                        implicitWidth: 40
                                        opacity: selectButton.checked ? 1 : 0
                                        x: selectButton.checked ? selectButton.x - 180 : selectButton.x
                                        onClicked: chapters.markSelectedAs(true)

                                        Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
                                        Behavior on x { XAnimator { easing.type:  Easing.InOutQuad } }
                                    }
                                    Button {
                                        id: markUnreadButton
                                        flat: true
                                        icon.name: "mark-as-unread"
                                        implicitWidth: 40
                                        x: selectButton.checked ? selectButton.x - 135 : selectButton.x
                                        opacity: selectButton.checked ? 1 : 0
                                        onClicked: chapters.markSelectedAs(false)

                                        Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
                                        Behavior on x { XAnimator { easing.type:  Easing.InOutQuad } }
                                    }
                                    Button {
                                        id: selectAllButton
                                        property bool selectionFlag: true
                                        flat: true
                                        icon.name: "select-all"
                                        implicitWidth: 40
                                        x: selectButton.checked ? selectButton.x - 90 : selectButton.x
                                        opacity: selectButton.checked ? 1 : 0
                                        onClicked: {
                                            chapters.selectRange(0, details.chapters_len - 1, selectionFlag)
                                            selectionFlag = !selectionFlag;
                                        }

                                        Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
                                        Behavior on x { XAnimator { easing.type:  Easing.InOutQuad } }
                                    }
                                    Button {
                                        id: downloadButton
                                        flat: true
                                        icon.name: "download"
                                        implicitWidth: 40
                                        opacity: selectButton.checked ? 1 : 0
                                        x: selectButton.checked ? selectButton.x - 45 : selectButton.x
                                        onClicked: {
                                            DownloadManager.append(chapters.getSelectedChapters(details.author));
                                            selectButton.checked = false;
                                        }

                                        Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
                                        Behavior on x { XAnimator { easing.type:  Easing.InOutQuad } }
                                    }
                                    Button {
                                        id: selectButton
                                        flat: true
                                        checkable: true
                                        icon.name: "select-chapters"
                                        implicitWidth: 40
                                        x: chaptersLabel.width - width
                                        z: 2
                                    }
                                }

                                ListView {
                                    id: view
                                    clip: true
                                    currentIndex: -1
                                    boundsBehavior: Flickable.StopAtBounds

                                    property int lastSelectedIndex: -1

                                    Layout.minimumHeight: Math.min(10, count) * 40
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true

                                    model: chapters

                                    delegate: ItemDelegate {
                                        width: parent.width
                                        onClicked: {
                                            if (selectButton.checked) {
                                                if (chapters.keyboardModifiers() & Qt.ShiftModifier)
                                                    chapters.selectRange(index, view.lastSelectedIndex, true);
                                                else {
                                                    model.selected = !model.selected;
                                                    view.lastSelectedIndex = index;
                                                }
                                            }
                                            else {
                                                SharedData.chapters = details.chapters;
                                                SharedData.currentMangaId = mangaId;
                                                SharedData.chapterIndex = index;
                                                SharedData.loadChapterDetails(model.id);
                                                model.read = true;
                                                settingsLoader.item.setValue(model.id, true);
                                            }
                                        }

                                        contentItem: RowLayout {
                                            CheckBox {
                                                id: checkBox
                                                checked: model.selected
                                                horizontalPadding: 0
                                                verticalPadding: 0
                                                visible: titleLabel.x == width + 5
                                                opacity: selectButton.checked ? 1 : 0
                                                onClicked: model.selected = !model.selected
                                            }
                                            Label {
                                                id: titleLabel
                                                elide: Text.ElideRight
                                                text: model.title ? model.title
                                                                  : qsTr("Chapter ") + model.number
                                                x: selectButton.checked ? checkBox.width + 5 : 0
                                                color: model.read ? "#7f7f7f" : Material.primaryTextColor

                                                Layout.fillWidth: true

                                                Behavior on x {
                                                    XAnimator {
                                                        duration: 220
                                                        easing.type: Easing.InOutQuad
                                                    }
                                                }
                                            }
                                            Label {
                                                text: new Date(model.date * 1000).toLocaleDateString(
                                                          Qt.locale(languageSettings.language), qsTr("MMM dd yyyy"))
                                            }
                                            Settings {
                                                id: languageSettings
                                                property string language
                                            }
                                        }
                                        ProgressBar {
                                            anchors {
                                                bottom: parent.bottom
                                                horizontalCenter: parent.horizontalCenter
                                                bottomMargin: 5
                                            }
                                            value: model.progress
                                            visible: model.queued
                                            width: parent.availableWidth

                                            Behavior on value { NumberAnimation {} }

                                            ToolTip.visible: hovered
                                            ToolTip.text: Math.floor(model.progress * 100) + "%"
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
                                            id: chapterNumber
                                            anchors.centerIn: parent
                                        }
                                    }
                                    ScrollBar.vertical: ScrollBar {
                                        id: scrollBar
                                        onPositionChanged: {
                                            if (pressed) {
                                                var row = Math.floor(details.chapters_len * position);
                                                chapterNumber.text = details.chapters[row][0];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Pane {
                        background: ThemedRectangle {}
                        implicitWidth: 246
                        Layout.alignment: Qt.AlignTop

                        ColumnLayout {
                            width: parent.width

                            Image {
                                id: coverImage
                                source: details.image
                                        ? "image://cover/" + details.image : ""
                                sourceSize {
                                    width: 222
                                    height: 316
                                }
                                visible: details.image
                                Layout.alignment: Qt.AlignHCenter
                            }
                            EmptyCover {
                                width: 222
                                height: 316
                                visible: !details.image
                            }
                            Label {
                                text: details.title
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignJustify
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Label {
                                text: qsTr("Alternative name(s)");
                                color: Material.accentColor
                                Layout.fillWidth: true
                            }
                            Repeater {
                                model: details.aka
                                delegate: Label {
                                    text: modelData
                                    horizontalAlignment: Text.AlignJustify
                                    textFormat: Text.RichText
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                            Label {
                                text: qsTr("Views")
                                color: Material.accentColor
                                Layout.fillWidth: true
                            }
                            Label {
                                text: details.hits
                                Layout.fillWidth: true
                            }
                            Label {
                                text: qsTr("Year of release")
                                color: Material.accentColor
                                visible: details.released
                                Layout.fillWidth: true
                            }
                            Label {
                                text: details.released
                                visible: details.released
                                Layout.fillWidth: true
                            }
                            Label {
                                text: qsTr("Author")
                                color: Material.accentColor
                                visible: details.artist
                                Layout.fillWidth: true
                            }
                            Label {
                                text: details.author
                                textFormat: Text.RichText
                                wrapMode: Text.WordWrap
                                visible: details.artist
                                Layout.fillWidth: true
                            }
                            Label {
                                text: qsTr("Artist")
                                color: Material.accentColor
                                visible: details.artist
                                Layout.fillWidth: true
                            }
                            Label {
                                text: details.artist
                                textFormat: Text.RichText
                                wrapMode: Text.WordWrap
                                visible: details.artist
                                Layout.fillWidth: true
                            }
                            Label {
                                text: qsTr("Type")
                                color: Material.accentColor
                                Layout.fillWidth: true
                            }
                            Label {
                                text: types[details.type]
                                Layout.fillWidth: true
                            }
                            Label {
                                text: qsTr("Status")
                                color: Material.accentColor
                                Layout.fillWidth: true
                            }
                            Label {
                                text: statuses[details.status]
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
