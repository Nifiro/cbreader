import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import Qt.labs.platform 1.1 as Platform
import Qt.labs.settings 1.1
import QtWinExtras 1.0

import com.cbreader.models 1.0
import DownloadManager 1.0

ApplicationWindow {
    id: mainWindow
    width: 888
    height: 600
    title: qsTr("Library")
    visible: true
    onClosing: {
        close.accepted = false
        if (!settings.dontAsk)
            closeAction.open()
        else
            settings.mimimizeToTray ? hide() : Qt.quit()
    }

    Material.theme: settings.theme
    Material.accent: settings.accent

    Component.onCompleted: {
        if (Qt.application.arguments.length > 1) {
            SharedData.path = "file:///" + Qt.application.arguments[1];
            SharedData.readOnline = false;
            SharedData.addRecent(SharedData.path);
            SharedData.mangaIndex = -1;
            reader.openManga()
        }
    }

    TaskbarButton {
        id: taskbarButton
        progress.visible: false
    }

    JumpList {
        recent.visible: true
    }

    Connections {
        target: DownloadManager
        onDownloadStarted: taskbarButton.progress.visible = true;
        onDownloadProgress: taskbarButton.progress.value = received / total * 100;
        onDownloadFinished: {
            if (!active) {
                trayIcon.showMessage(qsTr("Download complete"),
                                     author + " - " + title);
                alert(0);
            }
            taskbarButton.progress.visible = false;
        }
    }

    menuBar: MenuBar {
        visible: !SharedData.fullscreen

        Menu {
            title: qsTr("&File")

            MenuItem {
                text: qsTr("&Open")
                icon.name: "open"
                onTriggered: reader.open()
            }
            MenuItem {
                text: qsTr("&Add to Library")
                icon.name: "add-bookmark"
                onTriggered: {
                    tabBar.setCurrentIndex(0);
                    library.addManga();
                }
            }
            MenuItem {
                text: qsTr("&Resume Last File")
                icon.name: "resume-last"
                onClicked: reader.resumeLastFile()
            }
            Menu {
                title: qsTr("Open Recent")
                //                icon.name: "recent"

                Repeater {
                    model: SharedData.recentFiles
                    delegate: MenuItem {
                        text: fontMetrics.elidedText(
                                  SharedData.baseName(modelData),
                                  Qt.ElideRight,
                                  parent.width)
                        onTriggered: {
                            SharedData.path = modelData;
                            SharedData.mangaIndex = -1;
                            SharedData.readOnline = false;
                            SharedData.open();
                        }
                    }
                }
            }
            //            MenuItem {
            //                text: qsTr("Resume Recent")
            //                icon.name: "resume-recent"
            //            }

            MenuSeparator {}

            MenuItem {
                text: qsTr("&Save to File")
                icon.name: "save-to-file"
                enabled: SharedData.opened
                onTriggered: reader.saveToFile()
            }
            MenuItem {
                text: qsTr("Save to &Clipboard")
                icon.name: "save-to-clipboard"
                enabled: SharedData.opened
                onTriggered: reader.saveToClipboard()
            }

            MenuSeparator {}

            MenuItem {
                property bool fullscreen: settings.visibility === ApplicationWindow.FullScreen
                text: qsTr("F&ull screen")
                icon.name: fullscreen ? "fullscreen-exit" : "fullscreen"
                onClicked: {
                    if (fullscreen) {
                        mainWindow.showNormal();
                        fullscreen = false;
                    }
                    else {
                        mainWindow.showFullScreen();
                        fullscreen = true;
                    }
                }
            }
            MenuItem {
                text: qsTr("E&xit")
                icon.name: "close"
                onTriggered: close()
            }
        }

        Menu {
            enabled: SharedData.opened
            title: qsTr("&Read")

            MenuItem {
                text: qsTr("&First page")
                icon.name: "first-page"
                onTriggered: reader.firstPage()
            }
            MenuItem {
                text: qsTr("&Last page")
                icon.name: "last-page"
                onTriggered: reader.lastPage()
            }
            MenuItem {
                text: qsTr("&Next page")
                icon.name: "next-page"
                onTriggered: reader.nextPage()
            }
            MenuItem {
                text: qsTr("Pre&vious page")
                icon.name: "prev-page"
                onTriggered: reader.prevPage()
            }

            //            MenuSeparator {}

            //            Menu {
            //                title: qsTr("&Bookmarks")

            //                MenuItem {
            //                    text: qsTr("Add")
            //                    icon.name: "add-bookmark"
            //                }
            //                MenuItem {
            //                    text: qsTr("Go to")
            //                    icon.name: "go-to-bookmark"
            //                }
            //                MenuItem {
            //                    text: qsTr("Delete")
            //                    icon.name: "delete-bookmark"
            //                }
            //            }

            //            MenuItem {
            //                text: qsTr("&Thumbnails")
            //                checkable: true
            //                onTriggered: SharedData.thumbnails = checked
            //            }
        }

        Menu {
            title: qsTr("O&ptions")

            MenuItem {
                text: qsTr("&Configure")
                icon.name: "settings"
                onTriggered: settingsDialog.open()
            }
        }

        Menu {
            title: qsTr("&Help")

            MenuItem {
                text: qsTr("&Website")
                icon.name: "website"
            }

            MenuItem {
                text: qsTr("&About")
                icon.name: "about"
                onTriggered: aboutDialog.open()
            }
        }
    }

    footer: TabBar {
        id: tabBar
        width: parent.width
        currentIndex: view.currentIndex
        visible: !SharedData.fullscreen

        TabButton {
            icon.name: "library"
            text: qsTr("Library")
        }
        TabButton {
            icon.name: "discover"
            text: qsTr("Discover")
        }
        TabButton {
            icon.name: "favorite-border"
            text: qsTr("Favorites")
        }
        TabButton {
            icon.name: "reader"
            text: qsTr("Reader")
        }
    }

    Connections {
        target: SharedData
        onReady: tabBar.setCurrentIndex(3)
        onFilter: tabBar.setCurrentIndex(1)
    }

    FontMetrics {
        id: fontMetrics
        font.family: mainWindow.font.family
    }

    SwipeView {
        id: view
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        LibraryPage { id: library }
        StackView { initialItem: MangaList {} }
        StackView { initialItem: FavoritesPage {} }
        ReaderPage { id: reader }

        onCurrentIndexChanged: {
            if (MangaModel.status == MangaModel.Null && currentIndex == 1)
                MangaModel.getMangaList();
            if (FavoritesModel.status == FavoritesModel.Null && currentIndex == 2)
                FavoritesModel.loadModel();
            title = tabBar.itemAt(view.currentIndex).text
        }
    }

    Platform.SystemTrayIcon {
        id: trayIcon
        // @disable-check M16
        icon.source: "../icon.ico"
        visible: true

        menu: Platform.Menu {
            Platform.MenuItem {
                text: qsTr("Restore")
                onTriggered: mainWindow.show()
            }
            Platform.MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }
    }

    Timer {
        id: syncTimer
        interval: 3600 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: FavoritesModel.synchronize()
    }

    Connections {
        target: FavoritesModel
        onSyncFinished: {
            var mangaCount = Object.keys(FavoritesModel.updatedFavorites).length;
            var message = "";
            var newChaptersString = "";
            for (var title in FavoritesModel.updatedFavorites) {
                var newChaptersCount = FavoritesModel.updatedFavorites[title];
                newChaptersString = newChaptersCount > 1
                        ? qsTr(" new chapters.\n")
                        : qsTr(" new chapter.\n");
                message += title + " - " + newChaptersCount + newChaptersString;
            }
            if (mangaCount > 0)
                trayIcon.showMessage(mangaCount + qsTr(" manga have been updated"), message);
        }
        onStatusChanged: {
            if (FavoritesModel.status == FavoritesModel.Ready)
                syncTimer.start();
        }
    }

    Dialog {
        id: aboutDialog

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        parent: Overlay.overlay

        modal: true
        title: qsTr("Comic Book Reader")
        standardButtons: Dialog.Ok

        ColumnLayout {
            anchors.fill: parent

            Label { text: qsTr("Version: 1.0") }
            Label { text: qsTr("Contact: nifiro@outlook.com") }
            Label { text: qsTr("Author: Osman Shemshedinov") }
        }
    }

    Settings {
        id: settings
        property int theme: Material.Dark
        property string language
        property int accent: Material.Pink
        //        property alias x: mainWindow.x
        //        property alias y: mainWindow.y
        //        property alias width: mainWindow.width
        //        property alias height: mainWindow.height
        property alias visibility: mainWindow.visibility
        property bool dontAsk: false
        property bool mimimizeToTray: false
    }

    Dialog {
        id: settingsDialog
        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height) / 2
        width: Math.min(mainWindow.width, mainWindow.height) / 3 * 2
        parent: Overlay.overlay
        modal: true
        title: qsTr("Settings")
        standardButtons: Dialog.Ok | Dialog.Cancel

        property var locales: ["en_US", "ru_RU"]

        onAccepted: {
            settings.theme = themeBox.currentIndex
            settings.language = locales[languageBox.currentIndex]
            settings.accent = accentBox.accentColorValues[accentBox.currentIndex]
            settingsDialog.close()
        }
        onRejected: {
            themeBox.currentIndex = settings.theme
            settingsDialog.close()
        }

        contentItem: ColumnLayout {
            id: settingsColumn
            spacing: 20

            RowLayout {
                spacing: 10

                Label {
                    text: qsTr("Theme:")
                    elide: Text.ElideRight
                    Layout.preferredWidth: settingsDialog.width / 4
                }
                ComboBox {
                    id: themeBox
                    currentIndex: settings.theme
                    model: [qsTr("Light"), qsTr("Dark")]
                    Layout.fillWidth: true
                }
            }
            RowLayout {
                spacing: 10

                Label {
                    text: qsTr("Language:")
                    elide: Text.ElideRight
                    Layout.preferredWidth: settingsDialog.width / 4
                }
                ComboBox {
                    id: languageBox
                    property int languageIndex

                    model: [qsTr("English"), qsTr("Russian")]
                    currentIndex: settingsDialog.locales.indexOf(settings.language)
                    Layout.fillWidth: true
                    Component.onCompleted:
                        languageIndex = settingsDialog.locales.indexOf(settings.language)
                }
            }
            RowLayout {
                spacing: 10

                Label {
                    text: qsTr("Accent color:")
                    elide: Text.ElideRight
                    Layout.preferredWidth: settingsDialog.width / 4
                }
                ComboBox {
                    id: accentBox

                    property var accentColorValues: [
                        Material.Red, Material.Pink, Material.Purple, Material.DeepPurple,
                        Material.Indigo, Material.Blue, Material.LightBlue, Material.Cyan,
                        Material.Teal, Material.Green, Material.LightGreen, Material.Lime,
                        Material.Yellow, Material.Amber, Material.Orange, Material.DeepOrange,
                        Material.Brown, Material.Grey, Material.BlueGrey
                    ]
                    property var accentColorNames: [
                        qsTr("Red"), qsTr("Pink"), qsTr("Purple"), qsTr("Deep Purple"),
                        qsTr("Indigo"), qsTr("Blue"), qsTr("LightBlue"), qsTr("Cyan"),
                        qsTr("Teal"), qsTr("Green"), qsTr("Light Green"), qsTr("Lime"),
                        qsTr("Yellow"), qsTr("Amber"), qsTr("Orange"), qsTr("Deep Orange"),
                        qsTr("Brown"), qsTr("Grey"), qsTr("Blue Grey")
                    ]

                    leftPadding: 12
                    rightPadding: 12
                    verticalPadding: 6
                    displayText: accentColorNames[currentIndex]
                    model: accentColorValues
                    contentItem: RowLayout {
                        Rectangle {
                            Layout.preferredHeight: accentBox.availableHeight - 12
                            Layout.preferredWidth: accentBox.availableHeight - 12
                            color: Material.color(accentBox.accentColorValues[accentBox.currentIndex])
                        }
                        Label {
                            text: accentBox.displayText
                            Layout.fillWidth: true
                        }
                    }
                    delegate: ItemDelegate {
                        id: delegateRoot

                        width: parent.width
                        height: Material.buttonHeight

                        contentItem: RowLayout {
                            Rectangle {
                                Layout.preferredHeight: delegateRoot.availableHeight
                                Layout.preferredWidth: delegateRoot.availableHeight
                                color: Material.color(modelData)
                            }
                            Label {
                                text: accentBox.accentColorNames[index]
                                Layout.fillWidth: true
                            }
                        }
                    }
                    Layout.fillWidth: true
                    Component.onCompleted: currentIndex = settings.accent
                }
            }

            Label {
                text: qsTr("Restart required")
                color: Material.color(Material.Red)
                opacity: languageBox.currentIndex !== languageBox.languageIndex ? 1.0 : 0.0
                horizontalAlignment: Label.AlignHCenter
                verticalAlignment: Label.AlignVCenter
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    Dialog {
        id: closeAction
        anchors.centerIn: parent
        modal: true
        parent: Overlay.overlay
        padding: 3
        title: qsTr("\"Close\" button action")

        onAccepted: {
            settings.mimimizeToTray = minimizeButton.checked
            settings.dontAsk = dontAsk.checked
            minimizeButton.checked ? hide() : Qt.quit()
        }

        contentItem: Rectangle {
            color: mainWindow.Material.dialogColor
            border {
                color: mainWindow.Material.rippleColor
                width: 2
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RadioButton {
                    id: minimizeButton
                    text: qsTr("Minimize to system tray")
                }
                RadioButton {
                    text: qsTr("Exit program")
                    checked: true
                }
            }
        }

        footer: DialogButtonBox {
            alignment: Qt.AlignVCenter | Qt.AlignHCenter
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel

            CheckBox {
                id: dontAsk
                text: qsTr("Don't ask again")
                checked: settings.dontAsk
            }
        }
    }
}
