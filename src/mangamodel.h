#ifndef MANGAMODEL_H
#define MANGAMODEL_H

#include <QAbstractListModel>
#include <QJsonArray>
#include <QSortFilterProxyModel>

class QStringList;
class QNetworkReply;

class MangaModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Status status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(QString errorString READ errorString WRITE setErrorString NOTIFY errorStringChanged)
    Q_PROPERTY(int total READ total WRITE setTotal NOTIFY totalChanged)

public:
    explicit MangaModel(QObject *parent = nullptr);

    enum RoleNames {
        CategoryRole = Qt::UserRole + 1,
        HitsRole,
        YearRole,
        IdRole,
        ImageRole,
        LastUpdatedRole,
        LastChapterDateRole,
        StatusRole,
        TitleRole,
        FavoriteRole
    };

    enum Status {
        Null = 0,
        Loading,
        Ready,
        NoConnection,
        Error
    };

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role) override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    virtual QHash<int, QByteArray> roleNames() const override;

    Q_ENUM(Status)
    Q_ENUM(RoleNames)

    Q_INVOKABLE void loadModel();
    Q_INVOKABLE void getMangaList();

    Status status() const;
    void setStatus(const Status &value);

    QString errorString() const;
    void setErrorString(const QString &errorString);

    int total() const;
    void setTotal(int total);

signals:
    void statusChanged();
    void totalChanged();
    void errorStringChanged();

private:
    struct Manga
    {
        QString categories;
        int hits;
        int year;
        QString id;
        QString image;
        QString lastUpdated;
        qint64 lastChapterDate;
        QString status;
        QString title;
        bool favorite;
    };

    void getMangaArray(const QByteArray &data);

    QVector<Manga> m_mangaModel;
    QJsonArray m_mangaArray;
    Status m_status;
    QString m_errorString;
    int m_total;
};

#endif // MANGAMODEL_H
