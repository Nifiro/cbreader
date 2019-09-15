#ifndef CHAPTERSMODEL_H
#define CHAPTERSMODEL_H

#include <QAbstractListModel>

class ChaptersModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Status status READ status WRITE setStatus NOTIFY statusChanged)

public:
    explicit ChaptersModel(QObject *parent = nullptr);

    enum Role
    {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        DateRole,
        NumberRole,
        ProgressRole,
        SelectedRole,
        ReadRole,
        QueuedRole,
        RecentlyAdded
    };

    enum Status
    {
        Loading,
        Ready
    };

    Q_ENUM(Role)
    Q_ENUM(Status)

    Q_INVOKABLE void loadModel(const QVariantList &list, const QString &mangaId);
    Q_INVOKABLE QVariantList getSelectedChapters(QString author);
    Q_INVOKABLE void selectRange(int first, int last, bool check);
    Q_INVOKABLE void markSelectedAs(bool read);
    Q_INVOKABLE void updateProgress(const QString &chapterId, int received, int total);
    Q_INVOKABLE Qt::KeyboardModifiers keyboardModifiers();

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role) override;

    Status status() const;
    void setStatus(Status status);

signals:
    void statusChanged();

private:
    struct Chapter
    {
        QString id;
        QString title;
        double date;
        double number;
        double progress;
        bool selected;
        bool read;
        bool queued;
        bool recentlyAdded;

        bool operator==(const Chapter &c) { return id == c.id; }
    };

    QList<Chapter> m_chapters;
    Status m_status;
    QString m_mangaId;
};

#endif // CHAPTERSMODEL_H
