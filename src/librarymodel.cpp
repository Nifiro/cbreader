#include "cachemanager.h"
#include "librarymodel.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QtDebug>
#include <QtConcurrent/QtConcurrent>

LibraryModel::LibraryModel(QObject *parent)
    : QAbstractListModel(parent), m_status(Status::Null),
      m_total(0), m_modelChanged(false)
{
}

LibraryModel::~LibraryModel()
{
    storeModel();
}

int LibraryModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;

    return m_library.size();
}

QVariant LibraryModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    switch (role) {
    case ImageRole: return m_library.at(index.row()).image;
    case TitleRole: return m_library.at(index.row()).title;
    case AuthorRole: return m_library.at(index.row()).author;
    case PagesRole: return m_library.at(index.row()).pages;
    case ReadPagesRole: return m_library.at(index.row()).readPages;
    case PathRole: return m_library.at(index.row()).path;
    default: return QVariant();
    }
}

bool LibraryModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (data(index, role) != value) {
        m_modelChanged = true;
        Manga manga = m_library.at(index.row());
        switch (role) {
        case ReadPagesRole:
            manga.readPages = value.toInt();
            break;
        }
        m_library[index.row()] = manga;
        emit dataChanged(index, index, QVector<int>() << role);
        return true;
    }
    return false;
}

Qt::ItemFlags LibraryModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return Qt::ItemIsEditable;
}

QHash<int, QByteArray> LibraryModel::roleNames() const
{
    static const QHash<int, QByteArray> roles {
        { ImageRole, "image" },
        { TitleRole, "title" },
        { AuthorRole, "author" },
        { PagesRole, "pages" },
        { ReadPagesRole, "readPages" },
        { PathRole, "path" }
    };
    return roles;
}

void LibraryModel::loadModel()
{
    setStatus(Status::Loading);
    if (!CacheManager::isCached("library"))
    {
        setStatus(Status::Ready);
        return;
    }

    QThread *t = QThread::create([=]() {
        QByteArray data = CacheManager::loadModel("library");
        QJsonDocument json = QJsonDocument::fromJson(data);
        QJsonArray mangaList = json["library"].toArray();

        Manga manga;
        m_library.reserve(mangaList.size());
        for (int i = 0; i < mangaList.size(); ++i)
        {
            QJsonObject mangaObj = mangaList[i].toObject();
            manga.read(mangaObj);
            m_library.append(manga);
        }
    });
    connect(t, &QThread::finished, this, [=]() {
        beginInsertRows(QModelIndex(), 0, m_library.count() - 1);
        endInsertRows();
        setTotal(m_library.size());
        setStatus(Status::Ready);
        t->deleteLater();
    });
    t->start();
}

void LibraryModel::storeModel()
{
    if (m_modelChanged)
    {
        QJsonObject rootObject, tempObj;
        QJsonArray library;
        for (Manga& m : m_library)
        {
            m.write(tempObj);
            library.append(tempObj);
        }
        rootObject["library"] = library;
        QJsonDocument json(rootObject);
        CacheManager::storeModel("library", json.toJson());
    }
}

void LibraryModel::append(QString image, QString path, QString title, QString author, int totalChapters)
{
    m_modelChanged = true;

    Manga manga;
    manga.image = image;
    manga.title = title;
    manga.author = author;
    manga.pages = totalChapters;
    manga.path = path;
    manga.readPages = 0;

    int row = m_library.size();
    beginInsertRows(QModelIndex(), row, row);
    m_library.append(manga);
    endInsertRows();
}

void LibraryModel::remove(int row)
{
    Manga m = m_library.at(row);
    beginRemoveRows(QModelIndex(), row, row);
    m_library.removeAt(row);
    endRemoveRows();
    m_modelChanged = true;

    QString path = m.path.mid(8);
    QFileInfo fi(path);
    if (fi.isDir()) {
        QtConcurrent::run([path]() {
            QDir mangaDir(path);
            mangaDir.removeRecursively();
        });
    }
}

LibraryModel::Status LibraryModel::status() const
{
    return m_status;
}

int LibraryModel::total() const
{
    return m_total;
}

void LibraryModel::setStatus(LibraryModel::Status status)
{
    if (m_status == status)
        return;

    m_status = status;
    emit statusChanged();
}

void LibraryModel::setTotal(int total)
{
    if (m_total == total)
        return;

    m_total = total;
    emit totalChanged();
}
