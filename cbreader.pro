QT += quick network
CONFIG += c++11

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS _CRT_SECURE_NO_WARNINGS DEBUG_BUILD

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

#lupdate_only {
SOURCES += \
    src/archiveentryimageprovider.cpp \
    src/clipboardproxy.cpp \
    src/directory.cpp \
    src/document.cpp \
    src/librarymodel.cpp \
    src/unrar.cpp \
    src/main.cpp \
    src/natsort.cpp \
    src/mangamodel.cpp \
    src/downloadmanager.cpp \
    src/asyncimageprovider.cpp \
    src/asyncimageresponse.cpp \
    src/cachemanager.cpp \
    src/chaptersmodel.cpp \
    src/favoritesmodel.cpp
#    qml/*.qml
#}

RESOURCES += qml.qrc

win32:RC_ICONS += icon.ico

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    qml/3rdparty/lottie.min.js \
    qml/CustomTextField.qml \
    qml/LabeledRect.qml \
    qml/LottieAnimation.qml \
    qml/SharedData.qml \
    qml/TranslationPopup.qml \
    qml/main.qml \
    qml/MangaDetail.qml \
    qml/MangaList.qml \
    qml/ThemedRectangle.qml \
    qml/EmptyCover.qml \
    qml/FavoritesPage.qml \
    qml/LibraryPage.qml \
    qml/ReaderPage.qml \
    qml/NetworkFailure.qml \
    qml/SearchField.qml \
    qml/CategoriesPopup.qml \
    qml/private/HtmlImg.qml \
    qml/private/lottie_shim.js \
    qml/qmldir

CONFIG(debug, debug|release) {
    unix|win32: LIBS += -L$$PWD/lib/debug -lzip -llibzippp_static -lWinInet -lUnRAR
}
else {
    unix|win32: LIBS += -L$$PWD/lib/release -lzip -llibzippp_static -lWinInet -lUnRAR
}

INCLUDEPATH += $$PWD/include
DEPENDPATH += $$PWD/include

HEADERS += \
    src/archiveentryimageprovider.h \
    src/clipboardproxy.h \
    src/directory.h \
    src/document.h \
    src/librarymodel.h \
    src/unrar.h \
    src/natsort.h \
    src/mangamodel.h \
    src/networkmanager.h \
    src/downloadmanager.h \
    src/asyncimageprovider.h \
    src/asyncimageresponse.h \
    src/cachemanager.h \
    src/chaptersmodel.h \
    src/favoritesmodel.h

TRANSLATIONS += \
    translations/cbreader_en_US.ts \
    translations/cbreader_ru_RU.ts

include(lib/SortFilterProxyModel/SortFilterProxyModel.pri)

STATECHARTS +=
