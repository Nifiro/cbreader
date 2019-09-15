#include "downloadmanager.h"
#include "networkmanager.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QStringBuilder>

DownloadManager::DownloadManager(QObject *parent) : QObject(parent), m_status(Status::Finished) {}

void DownloadManager::append(QVariantList chapters)
{
    for (int i = 0; i < chapters.size(); i += 3)
    {
        Task task;
        task.id = chapters.at(i).toString();
        task.title = chapters.at(i + 1).toString();
        task.author = chapters.at(i + 2).toString();
        append(task);
    }
}

void DownloadManager::append(DownloadManager::Task task)
{
    if (m_downloadQueue.isEmpty() && m_status != Status::Downloading)
    {
        m_status = Status::Downloading;
        getChapterImages(task);
    }
    else
        m_chaptersQueue.append(task);
}

DownloadManager *DownloadManager::getManager()
{
    static DownloadManager *manager = new DownloadManager;
    return manager;
}

QString DownloadManager::libraryPath()
{
#ifdef DEBUG_BUILD
    return QStringLiteral("files/");
#else
    return QCoreApplication::applicationDirPath() + "/files/";
#endif
}

void DownloadManager::getChapterImages(Task task)
{
    m_currTask = task;
    m_chapterPath = libraryPath() % task.id % QStringLiteral("/");

    QDir chapterDir;
    if (!chapterDir.exists(m_chapterPath))
        chapterDir.mkpath(m_chapterPath);
    QNetworkRequest request;
    request.setUrl(QUrl("https://www.mangaeden.com/api/chapter/" % task.id % "/"));
    QNetworkReply *reply = NetworkManager::getManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [=]() {
        if (!reply->error())
        {
            QByteArray data = reply->readAll();
            QJsonDocument json = QJsonDocument::fromJson(data);
            if (!json.isNull() && json.isObject())
            {
                QJsonValue image;
                QString url;

                QJsonArray images = json["images"].toArray();

                m_currTask.ext = images.last().toArray()[1].toString().right(4);
                m_currTask.pages = images.count();

                for (int i = images.size() - 1; i >= 0; --i)
                {
                    image = images.at(i).toArray();
                    url = image[1].toString();
                    m_downloadQueue.enqueue(url);
                }
                emit downloadStarted();
                downloadNextImage(1);
            }
        }
        reply->deleteLater();
    });
}

void DownloadManager::downloadNextImage(int pageIndex)
{
    if (m_downloadQueue.isEmpty())
    {
        emit downloadFinished(QUrl::fromLocalFile(m_chapterPath % "1" + m_currTask.ext),
                              QUrl::fromLocalFile(m_chapterPath),
                              m_currTask.title, m_currTask.author, m_currTask.pages);

        if (!m_chaptersQueue.isEmpty())
            getChapterImages(m_chaptersQueue.dequeue());
        else
            m_status = Status::Finished;
    }
    else {
        const QString& imageUrl = m_downloadQueue.dequeue();
        QNetworkRequest request;
        request.setUrl(QUrl("https://cdn.mangaeden.com/mangasimg/" % imageUrl));
        QNetworkReply *reply = NetworkManager::getManager()->get(request);
        connect(reply, &QNetworkReply::finished, this, [=]() {
            if (!reply->error())
            {
                QString fileName = m_chapterPath % QString::number(pageIndex) % imageUrl.right(4);
                m_outputFile.setFileName(fileName);
                if (m_outputFile.open(QIODevice::WriteOnly))
                {
                    m_outputFile.write(reply->readAll());
                    m_outputFile.close();
                    qDebug() << pageIndex << "/" << m_currTask.pages;
                    emit downloadProgress(m_currTask.id, pageIndex, m_currTask.pages);
                    downloadNextImage(pageIndex + 1);
                }
            }
            else
                qDebug() << reply->errorString();
            reply->deleteLater();
        });
    }
}
