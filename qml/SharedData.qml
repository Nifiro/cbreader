pragma Singleton

import QtQuick 2.12
import Qt.labs.settings 1.1

import Document 1.0

Item {
    id: data

    property int page: 0
    property var images: []

    property var chapters: []
    property int chapterIndex
    property string currentMangaId

    property int pages: 0
    property string path
    property int mangaIndex: -1
    property bool fullscreen: false
    property bool opened: false
    property bool readOnline: false
    //    property bool thumbnails: false

    //---------------------------------------------------------------
    property var genres: [
        qsTr("Comedy"), qsTr("Martial Arts"), qsTr("Horror"), qsTr("Adventure"),
        qsTr("Doujinshi"), qsTr("Supernatural"), qsTr("Yaoi"), qsTr("Josei"),
        qsTr("Gender Bender"), qsTr("Shounen"), qsTr("Smut"), qsTr("Slice of Life"),
        qsTr("Tragedy"), qsTr("Fantasy"), qsTr("School Life"), qsTr("Psychological"),
        qsTr("Mystery"), qsTr("Yuri"), qsTr("Drama"), qsTr("One Shot"), qsTr("Mature"),
        qsTr("Sci-fi"), qsTr("Ecchi"), qsTr("Action"), qsTr("Sports"), qsTr("Adult"),
        qsTr("Mecha"), qsTr("Shoujo"), qsTr("Harem"), qsTr("Seinen"), qsTr("Historical"),
        qsTr("Romance")
    ]
    property string pattern
    property var selectedGenres: []

    //---------------------------------------------------------------
    property var recentFiles: []
    property url lastFile

    signal open
    signal ready
    signal filter

    Settings {
        id: recentFilesSettings
        property alias recentFiles: data.recentFiles
        property alias lastFile: data.lastFile
    }

    Loader {
        id: settingsLoader

        sourceComponent: Settings {
            category: currentMangaId
        }
    }

    onChapterIndexChanged: {
        settingsLoader.item.setValue("index", chapterIndex);
        settingsLoader.item.setValue("lastChapter", chapters[chapterIndex][3]);
        settingsLoader.active = false;
        settingsLoader.active = true;
//        console.log("SharedData::onChapterIndexChanged:", chapterIndex);
    }

    Component.onCompleted: selectedGenres.length = genres.length

    function isGenreSelected(genre) {
        return selectedGenres[genres.indexOf(genre)] === true;
    }

    function selectGenre(genre) {
        selectedGenres.fill(false);

        var index = genres.indexOf(genre);
        if (index !== -1) {
            selectedGenres[index] = true;
            // TODO: dirty hack
            selectedGenresChanged();
            pattern = genre;
            filter(index);
        }
    }

    function loadChapterDetails(id) {
        var request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.responseText)
                {
                    var images = JSON.parse(request.responseText)["images"];
                    SharedData.pages = images.length;
                    SharedData.readOnline = true;
                    SharedData.mangaIndex = -1;

                    var data = [];
                    for (var i = images.length - 1; i >= 0; i--)
                        data.push(images[i][1]);

                    SharedData.images = data;
                    SharedData.open();
                }
            }
        }
        request.open("GET",
                     "https://www.mangaeden.com/api/chapter/" + id + "/")
        request.send();
    }

    function baseName(str) {
        var path = str.toString();
        return path.slice(path.lastIndexOf("/") + 1);
    }

    function addRecent(file) {
        var fileName = Document.cleanPath(file);
        if (recentFiles.length >= 10)
            recentFiles.shift();
        recentFiles.push(fileName);
        lastFile = fileName;
    }
}
