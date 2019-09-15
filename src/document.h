#ifndef DOCUMENT_H
#define DOCUMENT_H

#include <QObject>
#include <QImage>
#include <QUrl>

#include "libzippp.h"

class Directory;
class Unrar;

class Document : public QObject
{
    Q_OBJECT

public:
    explicit Document(QObject *parent = nullptr);
    ~Document();

    enum OpenMode {
        Read,
        Append,
    };

    Q_ENUM(OpenMode)

    static Document *getDocument();

    Q_INVOKABLE bool open(const QUrl &file, OpenMode mode);
    Q_INVOKABLE QImage pageImage(int page) const;
    Q_INVOKABLE QString lastErrorString() const;
    Q_INVOKABLE int pages() const;
    Q_INVOKABLE bool isZip() const;
    Q_INVOKABLE QUrl path() const;
    Q_INVOKABLE QUrl firstPagePath() const;
    Q_INVOKABLE QStringList entries() const;
    Q_INVOKABLE QString cleanPath(const QString &path);
    Q_INVOKABLE void setOverrideCursor(const QString &filename);
    Q_INVOKABLE void restoreOverrideCursor();
    Q_INVOKABLE bool isDirectory() const;
    void close();

private:
    bool processArchive(const QString &fileName, Document::OpenMode mode);
    void processEntries(const QString &path);
    void extractFirstPage(const QString &fileName);

    QStringList m_pageMap;
    Directory *m_directory;
    Unrar *m_unrar;
    libzippp::ZipArchive *m_archive;
    QStringList m_entries;
    QString m_lastErrorString;
    QString m_firstPagePath;
    QString m_path;
};

#endif // DOCUMENT_H
