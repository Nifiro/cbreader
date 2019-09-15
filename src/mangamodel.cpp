#include <Windows.h>
#include <WinInet.h>
#include <QFile>
#include <QFutureWatcher>

#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QStringList>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QDateTime>
#include <QtDebug>
#include <QDir>

#include "cachemanager.h"
#include "mangamodel.h"
#include "networkmanager.h"

MangaModel::MangaModel(QObject *parent)
    : QAbstractListModel(parent), m_status(Status::Null), m_total(0) {}

int MangaModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;

    return m_mangaModel.count();
}

QVariant MangaModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    switch (role) {
    case CategoryRole: return m_mangaModel.at(index.row()).categories;
    case HitsRole: return m_mangaModel.at(index.row()).hits;
    case YearRole: return m_mangaModel.at(index.row()).year;
    case IdRole: return m_mangaModel.at(index.row()).id;
    case ImageRole: return m_mangaModel.at(index.row()).image;
    case LastUpdatedRole: return m_mangaModel.at(index.row()).lastUpdated;
    case LastChapterDateRole: return m_mangaModel.at(index.row()).lastChapterDate;
    case StatusRole: return m_mangaModel.at(index.row()).status;
    case TitleRole: return m_mangaModel.at(index.row()).title;
    case FavoriteRole: return m_mangaModel.at(index.row()).favorite;
    default: return QVariant();
    }
}

bool MangaModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (data(index, role) != value) {
        Manga manga = m_mangaModel.at(index.row());
        switch (role) {
        case FavoriteRole:
            manga.favorite = value.toBool();
            break;
        }
        m_mangaModel[index.row()] = manga;
        emit dataChanged(index, index, QVector<int>() << role);
        return true;
    }
    return false;
}

Qt::ItemFlags MangaModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return Qt::ItemIsEditable;
}

QHash<int, QByteArray> MangaModel::roleNames() const
{
    static const QHash<int, QByteArray> roles {
        { CategoryRole, "categories" },
        { HitsRole, "hits" },
        { YearRole, "year" },
        { IdRole, "id" },
        { ImageRole, "image" },
        { LastUpdatedRole, "lastUpdated" },
        { LastChapterDateRole, "lastChapterDate" },
        { StatusRole, "status" },
        { TitleRole, "title" },
        { FavoriteRole, "favorite" }
    };
    return roles;
}

void MangaModel::getMangaArray(const QByteArray &data)
{
    QJsonDocument document = QJsonDocument::fromJson(data);
    if (!document.isNull() && document.isObject())
    {
        setTotal(document["total"].toInt());
        m_mangaArray = document["manga"].toArray();
    }
}

int MangaModel::total() const
{
    return m_total;
}

void MangaModel::setTotal(int total)
{
    m_total = total;
    emit totalChanged();
}

QString MangaModel::errorString() const
{
    return m_errorString;
}

void MangaModel::setErrorString(const QString &errorString)
{
    m_errorString = errorString;
}

void MangaModel::getMangaList()
{
    setStatus(Status::Loading);
    QString modelPath = CacheManager::getJsonPath() + QStringLiteral("index");
    DWORD connectionFlags;
    if (InternetGetConnectedState(&connectionFlags, 0))
    {
        QNetworkRequest request;
        request.setUrl(QUrl("https://www.mangaeden.com/api/list/0/"));
        QNetworkReply *reply = NetworkManager::getManager()->get(request);
        connect(reply, &QNetworkReply::finished, this, [=]() {
            if (!reply->error())
            {
                QByteArray data = reply->readAll();
                CacheManager::storeModel("index", data);
                getMangaArray(data);
                loadModel();
            }
            else {
                setErrorString(reply->errorString());
                setStatus(Status::Error);
            }
            reply->deleteLater();
        });
    }
    else if (QFile::exists(modelPath))
    {
        QByteArray data = CacheManager::loadModel("index");
        if (!data.isEmpty()) {
            getMangaArray(data);
            loadModel();
        }
        else {
            setStatus(Status::Error);
        }
    }
    else {
        setStatus(Status::NoConnection);
    }
}

MangaModel::Status MangaModel::status() const
{
    return m_status;
}

void MangaModel::setStatus(const Status &value)
{
    m_status = value;
    emit statusChanged();
}

void MangaModel::loadModel()
{
    QThread *t = QThread::create([=]() {
        const QString statuses[] { tr("Suspended"), tr("Ongoing"),
                    tr("Completed") };

//        int total{ 0 };
//        QRegularExpression re(R"(.*(Yaoi|Josei|Gender Bender|Smut|Yuri|Mature|Ecchi|Adult|Harem).*)");
//        QRegularExpressionMatch match;
        for (int i = 0; i < m_total; i++)
        {
            QJsonValue manga = m_mangaArray.at(i);
            if(manga.isObject())
            {
                QJsonObject obj = manga.toObject();
                Manga newManga;

                newManga.categories = obj["c"].toVariant().toStringList().join(";");
//                match = re.match(newManga.categories);
//                if (match.hasMatch())
//                    continue;

                newManga.hits = obj["h"].toInt();
                newManga.id = obj["i"].toString();
                newManga.favorite = false;

                if(!obj["im"].isNull())
                    newManga.image = QStringLiteral("image://cover/") + obj["im"].toString();
                // newManga.image = QStringLiteral("../cache/thumbs/") + obj["im"].toString();
                // newManga.image = QStringLiteral("https://cdn.mangaeden.com/mangasimg/") + obj["im"].toString();

                if (obj.contains(QStringLiteral("ld")) && !obj["ld"].isNull())
                {
                    qint64 secsSinceEpoch = obj["ld"].toVariant().toLongLong();
                    newManga.lastChapterDate = secsSinceEpoch;
                    QDateTime lastUpdated = QDateTime::fromSecsSinceEpoch(secsSinceEpoch);
                    qint64 dayDifference = lastUpdated.daysTo(QDateTime::currentDateTime());
                    if (dayDifference <= 7)
                    {
                        if (dayDifference == 0)
                        {
                            qint64 secsDiff = lastUpdated.secsTo(QDateTime::currentDateTime());
                            newManga.lastUpdated = secsDiff / 3600 < 1 ?
                                        QString::number(secsDiff / 60) + tr(" mins ago") :
                                        QString::number(secsDiff / 3600) + tr(" hours ago");
                        }
                        else if (dayDifference == 1)
                            newManga.lastUpdated = tr("Yesterday");
                        else if (dayDifference == 7)
                            newManga.lastUpdated = tr("1 week ago");
                        else
                            newManga.lastUpdated = QString::number(dayDifference) + tr(" days ago");
                    }
                    else
                        newManga.lastUpdated = lastUpdated.toString(tr("MMM dd yyyy"));
                    newManga.year = lastUpdated.date().year();
                }
                else
                    newManga.lastUpdated = tr("No chapters");

                int statusId = obj["s"].toInt();
                newManga.status = statuses[statusId];
                newManga.title = obj["t"].toString();
                m_mangaModel.append(newManga);
//                total++;
            }
        }
//        setTotal(total);
    });
    connect(t, &QThread::finished, this, [=]() {
        beginInsertRows(QModelIndex(), 0, m_total - 1);
        endInsertRows();
        setStatus(Status::Ready);
        t->deleteLater();
    });
    t->start();
}
