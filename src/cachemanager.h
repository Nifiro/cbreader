#ifndef CACHEMANAGER_H
#define CACHEMANAGER_H

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QObject>
#include <QThread>

class CacheManager : public QObject
{
    Q_OBJECT

public:
    explicit CacheManager(QObject *parent = nullptr);

#ifndef DEBUG_BUILD
    static QString getJsonPath() { return QCoreApplication::applicationDirPath() + "/cache/json/"; }
    static QString getThumbsPath() { return QCoreApplication::applicationDirPath() + "/cache/thumbs/"; }
#else
    static QString getJsonPath() { return QStringLiteral("cache/json/"); }
    static QString getThumbsPath() { return QStringLiteral("cache/thumbs/"); }
#endif

    Q_INVOKABLE static void storeModel(const QString &fileName, const QByteArray &data);
    Q_INVOKABLE static QByteArray loadModel(const QString &fileName);
    Q_INVOKABLE static bool isCached(const QString &fileName);
};

#endif // CACHEMANAGER_H
