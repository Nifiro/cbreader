#ifndef ASYNCIMAGERESPONSE_H
#define ASYNCIMAGERESPONSE_H

#include <QNetworkReply>
#include <QQuickImageResponse>
#include <QRunnable>

class AsyncImageResponse : public QQuickImageResponse, public QRunnable
{
public:
    AsyncImageResponse(const QString &url, const QSize &requestedSize);

    void loadThumbnail();
    void run() override;
    QQuickTextureFactory *textureFactory() const override;

private:
    void replyFinished();

    QString m_url;
    QSize m_requestedSize;
    QImage m_image;
    QNetworkReply *m_reply;
    QNetworkAccessManager m_networkManager;
};

#endif // ASYNCIMAGERESPONSE_H
