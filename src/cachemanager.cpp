#include "cachemanager.h"

#include <QDir>
#include <QFile>
#include <QtConcurrent/QtConcurrent>

CacheManager::CacheManager(QObject *parent) : QObject(parent) {}

void CacheManager::storeModel(const QString &fileName, const QByteArray &data)
{
    QFile file(getJsonPath() + fileName);
    QDir cacheDir;
    if (!cacheDir.exists(getJsonPath()))
        cacheDir.mkpath(getJsonPath());
    if (file.open(QIODevice::WriteOnly))
        file.write(data);
}

QByteArray CacheManager::loadModel(const QString &fileName)
{
    QFile file(getJsonPath() + fileName);
    if (file.open(QIODevice::ReadOnly))
        return file.readAll();
    return QByteArray();
}

bool CacheManager::isCached(const QString &fileName)
{
    return QFile::exists(getJsonPath() + fileName);
}
