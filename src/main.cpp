#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QFontDatabase>
#include <QTranslator>
#include <QIcon>
#include <QSettings>

#include "archiveentryimageprovider.h"
#include "asyncimageprovider.h"
#include "cachemanager.h"
#include "chaptersmodel.h"
#include "clipboardproxy.h"
#include "document.h"
#include "downloadmanager.h"
#include "favoritesmodel.h"
#include "librarymodel.h"
#include "mangamodel.h"
#include "networkmanager.h"

static void registerTypes();

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setApplicationName("Comic Book Reader");
    QCoreApplication::setOrganizationName("Comic Book Software");
    QCoreApplication::setOrganizationDomain("com.cbsoftware");

    QGuiApplication app(argc, argv);

    app.setApplicationDisplayName("Comic Book Reader");

    QIcon::setThemeName("material");

    NetworkManager::getManager()->connectToHostEncrypted("https://www.mangaeden.com/eng/");

    registerTypes();

    QFontDatabase fontDatabase;
    if (fontDatabase.addApplicationFont(":/media/fonts/MaterialIcons-Regular.ttf") == -1)
        qWarning() << "Failed to load MaterialIcons-Regular.ttf";
    if (fontDatabase.addApplicationFont(":/media/fonts/Roboto-Regular.ttf") == -1)
        qWarning() << "Failed to load Roboto-Regular.ttf";

    QSettings settings;
    QString locale = settings.value("language", QLocale::system().name()).toString();
    QTranslator translator;
#ifndef DEBUG_BUILD
    if (translator.load(QCoreApplication::applicationDirPath() +
                        QStringLiteral("/translations/cbreader_") + locale))
#else
    if (translator.load(QStringLiteral("translations/cbreader_") + locale))
#endif
        app.installTranslator(&translator);

    QQmlApplicationEngine engine;
    engine.addImageProvider("cover", new AsyncImageProvider);
    engine.addImageProvider("archive", new ArchiveEntryImageProvider);
#ifndef DEBUG_BUILD
    engine.load(QUrl::fromLocalFile(
                    QCoreApplication::applicationDirPath() +
                    QStringLiteral("/qml/main.qml")));
#else
    engine.load(QUrl::fromLocalFile(QStringLiteral("qml/main.qml")));
#endif
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

static void registerTypes()
{
    qmlRegisterType<ChaptersModel>("com.cbreader.models", 1, 0, "ChaptersModel");
    qmlRegisterUncreatableType<NetworkManager>("NetworkManager", 1, 0, "NetworkManager",
                                               QStringLiteral("NetworkManager should not be created in QML"));
    qmlRegisterSingletonType<CacheManager>("CacheManager", 1, 0, "CacheManager",
                                           [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)

        CacheManager *cacheManager = new CacheManager();
        return cacheManager;
    });
    qmlRegisterSingletonType<DownloadManager>("DownloadManager", 1, 0, "DownloadManager",
                                              [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)

        return DownloadManager::getManager();
    });
    qmlRegisterSingletonType<FavoritesModel>("com.cbreader.models", 1, 0, "FavoritesModel",
                                             [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)

        return new FavoritesModel;
    });
    qmlRegisterSingletonType<MangaModel>("com.cbreader.models", 1, 0, "MangaModel",
                                         [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)

        return new MangaModel;
    });
    qmlRegisterSingletonType<LibraryModel>("com.cbreader.models", 1, 0, "LibraryModel",
                                           [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)

        return new LibraryModel;
    });
    qmlRegisterSingletonType<Document>("Document", 1, 0, "Document",
                                       [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)

        return Document::getDocument();
    });
    qmlRegisterSingletonType<ClipboardProxy>("ClipboardProxy", 1, 0, "ClipboardProxy",
                                             [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)

        return new ClipboardProxy(QGuiApplication::clipboard());
    });
}
