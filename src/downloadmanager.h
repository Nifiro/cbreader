#ifndef DOWNLOADMANAGER_H
#define DOWNLOADMANAGER_H

#include <QFile>
#include <QNetworkReply>
#include <QObject>
#include <QQueue>
#include <QUrl>

class DownloadManager : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE void append(QVariantList chapters);
    Q_INVOKABLE static DownloadManager* getManager();
    Q_INVOKABLE QString libraryPath();

signals:
    void downloadStarted();
    void downloadFinished(QUrl image, QUrl path, QString title, QString author, int pages);
    void chapterDownloaded(QString chapterId);
    void downloadProgress(QString chapterId, int received, int total);

private:
    struct Task
    {
        QString id;
        QString title;
        QString author;
        int pages;
        QString ext;
    };

    enum Status
    {
        Finished = 0,
        Downloading
    };    

    void append(Task task);
    void getChapterImages(Task task);
    void downloadNextImage(int pageIndex);

    DownloadManager(QObject *parent = nullptr);
    DownloadManager(const DownloadManager&) = delete;
    DownloadManager(DownloadManager&&) = delete;
    DownloadManager& operator=(const DownloadManager&) = delete;
    DownloadManager& operator=(DownloadManager&&) = delete;

    QQueue<QString> m_downloadQueue;
    QQueue<Task> m_chaptersQueue;
    QNetworkReply *m_currentDownload;
    QString m_chapterPath;
    Status m_status;
    QFile m_outputFile;
    Task m_currTask;
};

#endif // DOWNLOADMANAGER_H
