#include <QMimeDatabase>
#include <QtDebug>

#define RARDLL
#include "unrar/rar.hpp"

#include "downloadmanager.h"
#include "natsort.h"
#include "unrar.h"

Unrar::Unrar(QObject *parent) : QObject(parent), m_tempDir(nullptr) {}

Unrar::~Unrar() {
    delete m_tempDir;
}

bool Unrar::open(QString fileName, Document::OpenMode mode)
{
    m_fileName = fileName;

    RAROpenArchiveDataEx archiveData;
    RARHeaderDataEx headerData;
    memset(&archiveData, 0, sizeof(archiveData));
    memset(&headerData, 0, sizeof(headerData));

    wchar_t *data = new wchar_t[static_cast<uint64_t>(m_fileName.size() + 1)]{};
    wcscpy(data, m_fileName.toStdWString().data());
    archiveData.ArcNameW = data;
    archiveData.OpenMode = RAR_OM_LIST;
    HANDLE h = RAROpenArchiveEx(&archiveData);
    if (archiveData.OpenResult != ERAR_SUCCESS) {
        qDebug() << "Could not open file" << m_fileName;
        RARCloseArchive(h);
        return  false;
    }

    while (RARReadHeaderEx(h, &headerData) == ERAR_SUCCESS) {
        if (headerData.FileAttr == 32)
            m_entries << headerData.FileName;
        RARProcessFileW(h, RAR_SKIP, nullptr, nullptr);
    }

    std::sort(m_entries.begin(), m_entries.end(), caseSensitiveNaturalOrderLessThen);

    if (mode == Document::Read) {
        m_tempDir = new QTemporaryDir();
        if (!m_tempDir->isValid())
            return  false;
    } else {
        extractFirstPage();
    }

    RARCloseArchive(h);

    return true;
}

QStringList Unrar::list()
{
    return m_entries;
}

void Unrar::extractAll(QString path)
{
    path = path.mid(8);

    RAROpenArchiveDataEx archiveData;
    RARHeaderDataEx headerData;
    memset(&archiveData, 0, sizeof(archiveData));
    memset(&headerData, 0, sizeof(headerData));

    wchar_t *data = new wchar_t[static_cast<uint64_t>(m_fileName.size() + 1)]{};
    wcscpy(data, m_fileName.toStdWString().data());
    archiveData.ArcNameW = data;
    archiveData.OpenMode = RAR_OM_EXTRACT;
    HANDLE h = RAROpenArchiveEx(&archiveData);

    if (archiveData.OpenResult == ERAR_SUCCESS) {
        wchar_t *pathPtr = new wchar_t[static_cast<uint64_t>(path.size() + 1)]{};
        wcscpy(pathPtr, path.toStdWString().data());
        while (RARReadHeaderEx(h, &headerData) == ERAR_SUCCESS) {
            if (RARProcessFileW(h, RAR_EXTRACT, pathPtr, nullptr) != ERAR_SUCCESS) {
                qDebug() << "Error processing entry" << headerData.FileName;
            }
        }
        RARCloseArchive(h);
        delete[] pathPtr;
    }
    else {
        qDebug() << "Could not open file" << m_fileName;
        RARCloseArchive(h);
    }
    delete[] data;
}

void Unrar::extractFirstPage()
{
    RAROpenArchiveDataEx archiveData;
    RARHeaderDataEx headerData;
    memset(&archiveData, 0, sizeof(archiveData));
    memset(&headerData, 0, sizeof(headerData));

    wchar_t *archiveName = new wchar_t[static_cast<uint64_t>(m_fileName.size() + 1)]{};
    wcscpy(archiveName, m_fileName.toStdWString().data());
    archiveData.ArcNameW = archiveName;
    archiveData.OpenMode = RAR_OM_EXTRACT;
    HANDLE h = RAROpenArchiveEx(&archiveData);

    QString firstEntry = m_entries.first();
    if (archiveData.OpenResult == ERAR_SUCCESS) {
        QFileInfo fileInfo(m_fileName);
        QString libraryPath = DownloadManager::getManager()->libraryPath();
        QString filePath = libraryPath + fileInfo.completeBaseName() + QStringLiteral("/");
        m_firstPagePath = filePath + firstEntry;

        if (!QFileInfo::exists(filePath))
        {
            QDir dir;
            dir.mkpath(filePath);
        }
        wchar_t *path = new wchar_t[static_cast<uint64_t>(filePath.size() + 1)]{};
        wcscpy(path, filePath.toStdWString().data());

        while (RARReadHeaderEx(h, &headerData) == ERAR_SUCCESS) {
            if (firstEntry == QString::fromStdWString(headerData.FileNameW)) {
                if (RARProcessFileW(h, RAR_EXTRACT, path, nullptr) != ERAR_SUCCESS) {
                    qDebug() << "Error processing entry" << headerData.FileName;
                }
                break;
            } else {
                RARProcessFileW(h, RAR_SKIP, nullptr, nullptr);
            }
        }

        RARCloseArchive(h);
        delete[] path;
    }
    else {
        qDebug() << "Could not open file" << m_fileName;
        RARCloseArchive(h);
    }
    delete[] archiveName;
}

QString Unrar::path()
{
    return m_tempDir->path();
}

QImage Unrar::pageImage(int page)
{
    RAROpenArchiveDataEx archiveData;
    RARHeaderDataEx headerData;
    memset(&archiveData, 0, sizeof(archiveData));
    memset(&headerData, 0, sizeof(headerData));

    wchar_t *archiveName = new wchar_t[static_cast<uint64_t>(m_fileName.size() + 1)]{};
    wcscpy(archiveName, m_fileName.toStdWString().data());
    archiveData.ArcNameW = archiveName;
    archiveData.OpenMode = RAR_OM_EXTRACT;
    HANDLE h = RAROpenArchiveEx(&archiveData);
    delete[] archiveName;

    QString entry = m_entries.at(page);
    QString entryPath = m_tempDir->path() + QStringLiteral("/") + entry;
    QFileInfo info(entryPath);
    if (info.exists()) {
        QImage image;
        if (image.load(entryPath))
            return image;
        return QImage();
    } else if (archiveData.OpenResult == ERAR_SUCCESS) {
        wchar_t *path = new wchar_t[static_cast<uint64_t>(m_tempDir->path().size() + 1)]{};
        wcscpy(path, m_tempDir->path().toStdWString().data());

        while (RARReadHeaderEx(h, &headerData) == ERAR_SUCCESS) {
            if (entry == QString::fromStdWString(headerData.FileNameW)) {
                if (RARProcessFileW(h, RAR_EXTRACT, path, nullptr) == ERAR_SUCCESS) {
                    RARCloseArchive(h);
                    delete[] path;
                    QImage image;
                    if (image.load(entryPath))
                        return image;
                    return QImage();
                }
                else {
                    qDebug() << "Error processing entry" << headerData.FileName;
                    RARCloseArchive(h);
                    delete[] path;
                    return QImage();
                }
            } else {
                RARProcessFileW(h, RAR_SKIP, nullptr, nullptr);
            }
        }

        RARCloseArchive(h);
        delete[] path;
        return QImage();
    }
    else {
        qDebug() << "Could not open file" << m_fileName;
        RARCloseArchive(h);
        return QImage();
    }
}

QString Unrar::firstPagePath() const
{
    return m_firstPagePath;
}
