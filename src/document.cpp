#include "document.h"

#include <algorithm>

#include <QGuiApplication>
#include <QScopedPointer>
#include <QImageReader>

#include <QMimeType>
#include <QMimeDatabase>
#include <QIODevice>
#include <QCursor>
#include <QPixmap>

#include <memory>

#include "directory.h"
#include "downloadmanager.h"
#include "natsort.h"
#include "unrar.h"

using std::sort;
using namespace libzippp;

Document::Document(QObject *parent) : QObject(parent),
    m_directory(nullptr), m_unrar(nullptr), m_archive(nullptr)
{
}

Document::~Document()
{
    close();
}

bool Document::open(const QUrl &file, OpenMode mode)
{
    close();

    QString fileName = file.toLocalFile();
    if (!QFileInfo::exists(fileName))
        return false;

    QMimeDatabase db;
    const QMimeType mime = db.mimeTypeForFile(fileName);

    if (mime.inherits(QStringLiteral("application/x-cbz")) ||
            mime.inherits( QStringLiteral("application/zip")))
    {
        m_archive = new ZipArchive(fileName.toStdString());

        if (!processArchive(fileName, mode))
            return false;

        m_path = fileName;
    }
    else if (mime.inherits( QStringLiteral("application/x-cbr")) ||
             mime.inherits( QStringLiteral("application/x-rar")) ||
             mime.inherits( QStringLiteral("application/vnd.rar")))
    {
        m_unrar = new Unrar();
        m_path = fileName;

        if (!m_unrar->open(fileName, mode))
        {
            delete m_unrar;
            m_unrar = nullptr;

            return false;
        }

        m_entries = m_unrar->list();
        m_firstPagePath = m_unrar->firstPagePath();
    }
    else if (mime.inherits(QStringLiteral("inode/directory")))
    {
        m_directory = new Directory();
        if (!fileName.endsWith(QStringLiteral("/")))
            fileName += QStringLiteral("/");

        if (!m_directory->open(fileName))
        {
            delete m_directory;
            m_directory = nullptr;

            return false;
        }

        m_path = fileName;
        m_entries = m_directory->list();
        std::sort(m_entries.begin(), m_entries.end(), caseSensitiveNaturalOrderLessThen);
        m_firstPagePath = fileName + m_entries.first();
    }
    else
    {
        m_lastErrorString = tr("Unknown ComicBook format.");
        return false;
    }

    return true;
}

void Document::close()
{
    m_lastErrorString.clear();

    if (!(m_archive || m_unrar || m_directory))
        return;

    if (m_archive && m_archive->isOpen())
        m_archive->close();
    delete m_archive;
    m_archive = nullptr;
    delete m_directory;
    m_directory = nullptr;
    delete m_unrar;
    m_unrar = nullptr;
    m_pageMap.clear();
    m_entries.clear();
}

int Document::pages() const
{
    return m_entries.size();
}

bool Document::isZip() const
{
    return m_archive != nullptr;
}

QUrl Document::path() const
{
    return QUrl::fromLocalFile(m_path);
}

QUrl Document::firstPagePath() const
{
    return QUrl::fromLocalFile(m_firstPagePath);
}

QStringList Document::entries() const
{
    return m_entries;
}

QString Document::cleanPath(const QString &path)
{
    return QDir::cleanPath(path);
}

void Document::setOverrideCursor(const QString &filename)
{
    QPixmap pixmap(filename);
    pixmap.scaled(32, 32, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    QCursor cursor(pixmap);
    QGuiApplication::setOverrideCursor(cursor);
}

void Document::restoreOverrideCursor()
{
    QGuiApplication::restoreOverrideCursor();
}

bool Document::isDirectory() const
{
    return m_directory != nullptr;
}

Document *Document::getDocument()
{
    static Document *document = new Document;
    return document;
}

bool Document::processArchive(const QString &fileName, OpenMode mode)
{
    if (!m_archive->open(ZipArchive::READ_ONLY))
    {
        delete m_archive;
        m_archive = nullptr;

        return false;
    }

    std::vector<ZipEntry> entries = m_archive->getEntries();
    if (entries.empty())
    {
        delete m_archive;
        m_archive = nullptr;

        return false;
    }

    for (const ZipEntry &entry : entries)
        if (entry.isFile())
            m_entries << entry.getName().data();

    std::sort(m_entries.begin(), m_entries.end(), caseSensitiveNaturalOrderLessThen);
    if (mode == OpenMode::Append)
        extractFirstPage(fileName);

    return true;
}

void Document::processEntries(const QString &path)
{
    QMimeDatabase db;
    for (const QString &fileName : m_entries)
    {
        const QMimeType mime = db.mimeTypeForFile(path + fileName);
        if (mime.name().startsWith(QStringLiteral("image")))
            m_entries << fileName;
    }
}

void Document::extractFirstPage(const QString &fileName)
{
    QFileInfo fileInfo(fileName);
    QString libraryPath = DownloadManager::getManager()->libraryPath();
    QString filePath = libraryPath + fileInfo.baseName() + QStringLiteral("/");

    if (!QFileInfo::exists(filePath))
    {
        QDir dir;
        dir.mkpath(filePath);
    }

    ZipEntry entry = m_archive->getEntry(m_entries.first().toStdString());
    std::string data = entry.readAsText();

    fileInfo.setFile(m_entries.first());
    m_firstPagePath = filePath + fileInfo.fileName();
    QFile file(m_firstPagePath);

    if (file.open(QIODevice::WriteOnly))
    {
        file.write(data.data(), static_cast<qint64>(entry.getSize()));
        file.close();
    }
}

QImage Document::pageImage(int page) const
{
    if (page >= m_entries.size())
        return QImage();

    if (isZip()) {
        ZipEntry entry = m_archive->getEntry(m_entries[page].toStdString());

        if (entry.isNull())
            return QImage();

        return QImage::fromData(
                    QByteArray::fromRawData(
                        entry.readAsText().data(),
                        static_cast<int>(entry.getSize())
                        )
                    );
    }
    else {
        return m_unrar->pageImage(page);
    }
}

QString Document::lastErrorString() const
{
    return m_lastErrorString;
}
