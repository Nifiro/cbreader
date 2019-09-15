#include "cachemanager.h"
#include "favoritesmodel.h"
#include "networkmanager.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QDateTime>
#include <QtDebug>
#include <QNetworkReply>

FavoritesModel::FavoritesModel(QObject *parent)
    : QAbstractListModel(parent), m_reply(nullptr), m_status(Status::Null),
      m_total(0), m_modelChanged(false), m_currSyncIndex(0)
{
}

FavoritesModel::~FavoritesModel()
{
    storeModel();
}

int FavoritesModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;

    return m_favorites.count();
}

QVariant FavoritesModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    switch (role) {
    case IdRole: return m_favorites.at(index.row()).id;
    case ImageRole: return m_favorites.at(index.row()).image;
    case TitleRole: return m_favorites.at(index.row()).title;
    case AuthorRole: return m_favorites.at(index.row()).author;
    case TotalChaptersRole: return m_favorites.at(index.row()).totalChapters;
    case NewChaptersRole: return m_favorites.at(index.row()).newChapters;
    case AddedAtRole: return m_favorites.at(index.row()).addedAt;
    default: return QVariant();
    }
}

bool FavoritesModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (data(index, role) != value) {
        Favorite manga = m_favorites.at(index.row());
        switch (role) {
        case TotalChaptersRole:
            manga.totalChapters = value.toInt();
            break;
        case NewChaptersRole:
            manga.newChapters = value.toInt();
            break;
        case AddedAtRole:
            manga.addedAt = value.toLongLong();
            break;
        }
        m_favorites[index.row()] = manga;
        emit dataChanged(index, index, QVector<int>() << role);
        m_modelChanged = true;
        return true;
    }
    return false;
}

Qt::ItemFlags FavoritesModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return Qt::ItemIsEditable;
}

QHash<int, QByteArray> FavoritesModel::roleNames() const
{
    static const QHash<int, QByteArray> roles {
        { IdRole, "id" },
        { ImageRole, "image" },
        { TitleRole, "title" },
        { AuthorRole, "author" },
        { TotalChaptersRole, "totalChapters" },
        { NewChaptersRole, "newChapters" },
        { AddedAtRole, "addedAt" }
    };
    return roles;
}

void FavoritesModel::append(QString id, QString image, QString title,
                            QString author, int chapters)
{
    if (!m_mangaIds.contains(id))
    {
        m_modelChanged = true;
        m_mangaIds.append(id);

        Favorite manga;
        manga.id = id;
        manga.title = title;
        manga.image = image;
        manga.author = author;
        manga.totalChapters = chapters;
        manga.newChapters = 0;
        manga.addedAt = QDateTime::currentSecsSinceEpoch();

        int row = m_favorites.size();
        beginInsertRows(QModelIndex(), row, row);
        m_favorites.append(manga);
        endInsertRows();
        setTotal(m_total + 1);
    }
}

void FavoritesModel::storeModel()
{
    if (m_modelChanged) {
        QJsonObject rootObject, tempObj;
        QJsonArray favorites;
        for (Favorite& f : m_favorites)
        {
            f.write(tempObj);
            favorites.append(tempObj);
        }
        rootObject["favorites"] = favorites;
        QJsonDocument json(rootObject);
        CacheManager::storeModel("favorites", json.toJson());
    }
}

void FavoritesModel::loadModel()
{
    setStatus(Status::Loading);
    if (!CacheManager::isCached("favorites"))
    {
        setStatus(Status::Ready);
        return;
    }

    QThread *t = QThread::create([=]() {
        QByteArray data = CacheManager::loadModel("favorites");
        QJsonDocument json = QJsonDocument::fromJson(data);
        QJsonArray mangaList = json["favorites"].toArray();

        Favorite manga;
        m_favorites.reserve(mangaList.size());
        for (int i = 0; i < mangaList.size(); ++i)
        {
            QJsonObject mangaObj = mangaList[i].toObject();
            manga.read(mangaObj);
            m_favorites.append(manga);
            m_mangaIds.append(manga.id);
        }
    });
    connect(t, &QThread::finished, this, [=]() {
        beginInsertRows(QModelIndex(), 0, m_favorites.count() - 1);
        endInsertRows();
        setTotal(m_favorites.count());
        setStatus(Status::Ready);
        t->deleteLater();
    });
    t->start();
}

bool FavoritesModel::contains(const QString &id)
{
    return m_mangaIds.contains(id);
}

void FavoritesModel::remove(const QString &id)
{
    int index = m_mangaIds.indexOf(id);
    if (index != -1)
    {
        m_modelChanged = true;
        beginRemoveRows(QModelIndex(), index, index);
        m_favorites.removeAt(index);
        endRemoveRows();
        setTotal(m_total - 1);
        m_mangaIds.removeAt(index);
    }
}

FavoritesModel::Status FavoritesModel::status() const
{
    return m_status;
}

int FavoritesModel::total() const
{
    return m_total;
}

QVariantMap FavoritesModel::updatedFavorites() const
{
    return m_updatedFavorites;
}

void FavoritesModel::setStatus(Status status)
{
    m_status = status;
    emit statusChanged();
}

void FavoritesModel::setTotal(int total)
{
    if (m_total == total)
        return;

    m_total = total;
    emit totalChanged();
}

void FavoritesModel::append(const FavoritesModel::Favorite &manga)
{
    append(manga.id, manga.image, manga.title, manga.author, manga.totalChapters);
}

void FavoritesModel::synchronize()
{
    if (m_status != Status::Syncing && NetworkManager::isOnline())
    {
        m_updatedFavorites.clear();
        m_currSyncIndex = 0;
        setStatus(Status::Syncing);
        syncFavorites();
    }
}

void FavoritesModel::syncFavorites()
{
    if (m_currSyncIndex >= m_favorites.size())
    {
        setStatus(Status::Ready);
        emit syncFinished();
        return;
    }

    QNetworkRequest request;
    QString id = data(index(m_currSyncIndex), IdRole).toString();
    request.setUrl("https://www.mangaeden.com/api/manga/" + id + "/");
    m_reply = NetworkManager::getManager()->get(request);
    connect(m_reply, &QNetworkReply::finished, this, [=]() {
        if (!m_reply->error())
        {
            QByteArray replyData = m_reply->readAll();
            QJsonDocument json = QJsonDocument::fromJson(replyData);
            QJsonObject rootObject = json.object();
            int chaptersLen = rootObject["chapters_len"].toInt();
            int totalChapters = data(index(m_currSyncIndex), TotalChaptersRole).toInt();
            QString title = data(index(m_currSyncIndex), TitleRole).toString();
            int newChapters = chaptersLen - totalChapters;

            if (newChapters > 0)
            {
                m_updatedFavorites.insert(title, newChapters);
                emit updatedFavoritesChanged();
                setData(index(m_currSyncIndex), newChapters, NewChaptersRole);
            }
            m_currSyncIndex++;
        }
        m_reply->deleteLater();
        syncFavorites();
    });
}
