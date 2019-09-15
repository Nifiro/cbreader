#include "asyncimageresponse.h"
#include "cachemanager.h"
#include "networkmanager.h"

#include <QDir>
#include <QFile>
#include <QThread>
#include <QThreadPool>

AsyncImageResponse::AsyncImageResponse(const QString &url, const QSize &requestedSize)
    : m_url(url), m_requestedSize(requestedSize), m_networkManager(this)
{
    setAutoDelete(false);
}

void AsyncImageResponse::loadThumbnail()
{
    QString imagePath = CacheManager::getThumbsPath() + m_url;
    if (QFileInfo::exists(imagePath))
        QThreadPool::globalInstance()->start(this);
    else
    {
        QNetworkRequest request("https://cdn.mangaeden.com/mangasimg/" + m_url);
        m_reply = m_networkManager.get(request);
        connect(m_reply, &QNetworkReply::finished, this, &AsyncImageResponse::replyFinished);
    }
}

void AsyncImageResponse::run()
{
    QString imagePath = CacheManager::getThumbsPath() + m_url;
    m_image.load(imagePath);
    if (m_requestedSize.isValid()/* && m_image.size() != m_requestedSize*/)
        m_image = m_image.scaled(m_requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    emit finished();
}

QQuickTextureFactory *AsyncImageResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

void AsyncImageResponse::replyFinished()
{
    if (!m_reply->error())
    {
        m_image.loadFromData(m_reply->readAll());
        if (!m_image.isNull())
        {
            QDir imageDir;
            QString path = CacheManager::getThumbsPath() + m_url.left(3);
            if (!imageDir.exists(path))
                imageDir.mkpath(path);
            //            m_image.save(CacheManager::THUMBS_PATH + m_url);
            if (m_requestedSize.isValid())
            {
                m_image.save(CacheManager::getThumbsPath() + m_url);
                m_image = m_image.scaled(m_requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            }
        }
    }

    m_reply->deleteLater();
    emit finished();
}
