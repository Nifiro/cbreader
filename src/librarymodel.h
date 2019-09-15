#ifndef LIBRARYMODEL_H
#define LIBRARYMODEL_H

#include <QAbstractListModel>
#include <QJsonObject>

class LibraryModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Status status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(int total READ total WRITE setTotal NOTIFY totalChanged)

public:
    explicit LibraryModel(QObject *parent = nullptr);
    virtual ~LibraryModel() override;

    enum RoleNames {
        CategoryRole = Qt::UserRole + 1,
        AuthorRole,
        ImageRole,
        PagesRole,
        PathRole,
        ReadPagesRole,
        TitleRole
    };

    enum Status {
        Null = 0,
        Loading,
        Ready
    };

    Q_ENUM(RoleNames)
    Q_ENUM(Status)

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void loadModel();
    Q_INVOKABLE void storeModel();
    Q_INVOKABLE void append(QString image, QString path, QString title, QString author, int pages);
    Q_INVOKABLE void remove(int row);

    Status status() const;
    int total() const;

public slots:
    void setStatus(Status status);
    void setTotal(int total);

signals:
    void statusChanged();
    void totalChanged();

private:
    struct Manga
    {
        QString image;
        QString title;
        QString author;
        QString path;
        int pages;
        int readPages;

        void read(QJsonObject &json)
        {
            image = json["image"].toString();
            title = json["title"].toString();
            author = json["author"].toString();
            pages = json["pages"].toInt();
            readPages = json["readPages"].toInt();
            path = json["path"].toString();
        }

        void write(QJsonObject &json)
        {
            json["image"] = image;
            json["title"] = title;
            json["author"] = author;
            json["pages"] = pages;
            json["readPages"] = readPages;
            json["path"] = path;
        }
    };

    QVector<Manga> m_library;
    Status m_status;
    int m_total;
    bool m_modelChanged;
};

#endif // LIBRARYMODEL_H
