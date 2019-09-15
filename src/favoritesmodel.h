#ifndef FAVORITESMODEL_H
#define FAVORITESMODEL_H

#include <QAbstractListModel>
#include <QJsonObject>
#include <QNetworkReply>

class FavoritesModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Status status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(int total READ total WRITE setTotal NOTIFY totalChanged)
    Q_PROPERTY(QVariantMap updatedFavorites READ updatedFavorites NOTIFY updatedFavoritesChanged)

public:
    explicit FavoritesModel(QObject *parent = nullptr);
    virtual ~FavoritesModel() override;

    enum {
        IdRole = Qt::UserRole + 1,
        ImageRole,
        TitleRole,
        AuthorRole,
        TotalChaptersRole,
        NewChaptersRole,
        AddedAtRole,
    };

    enum Status {
        Null = 0,
        Loading,
        Syncing,
        Ready
    };

    Q_ENUM(Status)

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role) override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE void append(QString id, QString image, QString title,
                            QString author, int chapters);
    Q_INVOKABLE void storeModel();
    Q_INVOKABLE void loadModel();
    Q_INVOKABLE bool contains(const QString &id);
    Q_INVOKABLE void remove(const QString &id);
    Q_INVOKABLE void synchronize();

    Status status() const;
    int total() const;

    QVariantMap updatedFavorites() const;

public slots:
    void setStatus(Status status);
    void setTotal(int total);

signals:
    void statusChanged();
    void totalChanged();
    void syncFinished();
    void updatedFavoritesChanged();

private:
    struct Favorite {
        QString id;
        QString image;
        QString title;
        QString author;
        int totalChapters;
        int newChapters;
        qint64 addedAt;

        void read(QJsonObject &json)
        {
            id = json["id"].toString();
            image = json["image"].toString();
            title = json["title"].toString();
            author = json["author"].toString();
            totalChapters = json["totalChapters"].toInt();
            newChapters = json["newChapters"].toInt();
            addedAt = json["addedAt"].toVariant().toLongLong();
        }

        void write(QJsonObject &json)
        {
            json["id"] = id;
            json["image"] = image;
            json["title"] = title;
            json["author"] = author;
            json["totalChapters"] = totalChapters;
            json["newChapters"] = newChapters;
            json["addedAt"] = addedAt;
        }
    };

    void append(const Favorite &manga);
    void syncFavorites();

    QVector<Favorite> m_favorites;
    QStringList m_mangaIds;
    QNetworkReply *m_reply;
    Status m_status;
    int m_total;
    bool m_modelChanged;
    int m_currSyncIndex;
    QVariantMap m_updatedFavorites;
};

#endif // FAVORITESMODEL_H
