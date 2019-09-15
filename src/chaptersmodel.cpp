#include <QGuiApplication>
#include <QSettings>
#include <QThread>
#include <QtDebug>

#include "chaptersmodel.h"

ChaptersModel::ChaptersModel(QObject *parent)
    : QAbstractListModel(parent), m_status(Loading) {}

void ChaptersModel::loadModel(const QVariantList &list, const QString &mangaId)
{
    setStatus(Status::Loading);
    m_mangaId = mangaId;
    if (list.isEmpty())
    {
        setStatus(Status::Ready);
        return;
    }
    QThread *t = QThread::create([=]() {
        QSettings settings;
        settings.beginGroup(mangaId);

        Chapter newChapter;
        newChapter.selected = false;
        newChapter.progress = 0.0;
        newChapter.queued = false;

        for (const QVariant &chapter : list)
        {
            QList<QVariant> ch = chapter.toList();
            newChapter.number = ch[0].toDouble();
            newChapter.date = ch[1].toDouble();
            newChapter.title = ch[2].toString();
            newChapter.id = ch[3].toString();
            newChapter.read = settings.value(newChapter.id, false).toBool();
            m_chapters.append(newChapter);
        }
        settings.endGroup();
    });
    connect(t, &QThread::finished, this, [=]() {
        beginInsertRows(QModelIndex(), 0, m_chapters.count() - 1);
        endInsertRows();
        setStatus(Status::Ready);
        t->deleteLater();
    });
    t->start();
}

QVariantList ChaptersModel::getSelectedChapters(QString author)
{
    QString title;
    QVariantList result;

    for (int i = 0; i < m_chapters.count(); ++i) {
        const Chapter &ch = m_chapters.at(i);
        if (ch.selected && !ch.queued)
        {
            setData(index(i), true, QueuedRole);
            title = ch.title.isEmpty() ?
                        tr("Chapter ") + QString::number(ch.number) :
                        ch.title;
            result << ch.id << title << author;
        }
    }
    return result;
}

void ChaptersModel::selectRange(int first, int last, bool check)
{
    int min = qMin(first, last);
    int max = qMax(first, last);
    for (int i = min; i <= max; ++i) {
        setData(index(i), check, SelectedRole);
    }
}

void ChaptersModel::markSelectedAs(bool read)
{
    QSettings settings;
    settings.beginGroup(m_mangaId);
    for (int i = 0; i < m_chapters.size(); ++i)
    {
        QModelIndex idx = index(i);
        if (data(idx, SelectedRole).toBool())
        {
            setData(idx, read, ReadRole);
            setData(idx, false, SelectedRole);
            settings.setValue(data(idx, IdRole).toString(), read);
        }
    }
    settings.endGroup();
}

void ChaptersModel::updateProgress(const QString &chapterId, int received, int total)
{
    Chapter ch;
    ch.id = chapterId;
    int chapterIndex = m_chapters.indexOf(ch);
    if (chapterIndex != -1)
    {
        setData(index(chapterIndex), static_cast<double>(received) / total, ProgressRole);
        if (received == total)
            setData(index(chapterIndex), false, QueuedRole);
    }
}

Qt::KeyboardModifiers ChaptersModel::keyboardModifiers()
{
    return QGuiApplication::keyboardModifiers();
}

int ChaptersModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;

    return m_chapters.count();
}

Qt::ItemFlags ChaptersModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return Qt::ItemIsEditable;
}

QVariant ChaptersModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    switch (role) {
    case IdRole: return m_chapters.at(index.row()).id;
    case TitleRole: return m_chapters.at(index.row()).title;
    case DateRole: return m_chapters.at(index.row()).date;
    case NumberRole: return m_chapters.at(index.row()).number;
    case ProgressRole: return m_chapters.at(index.row()).progress;
    case SelectedRole: return m_chapters.at(index.row()).selected;
    case ReadRole: return m_chapters.at(index.row()).read;
    case QueuedRole: return m_chapters.at(index.row()).queued;
    case RecentlyAdded: return m_chapters.at(index.row()).recentlyAdded;
    default: return QVariant();
    }
}

bool ChaptersModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (data(index, role) != value) {
        Chapter ch = m_chapters.at(index.row());
        switch (role) {
        case SelectedRole:
            ch.selected = value.toBool();
            break;
        case ProgressRole:
            ch.progress = value.toDouble();
            break;
        case ReadRole:
            ch.read = value.toBool();
            break;
        case QueuedRole:
            ch.queued = value.toBool();
            break;
        case RecentlyAdded:
            ch.recentlyAdded = value.toBool();
            break;
        }
        m_chapters[index.row()] = ch;
        emit dataChanged(index, index, QVector<int>() << role);
        return true;
    }
    return false;
}

ChaptersModel::Status ChaptersModel::status() const
{
    return m_status;
}

void ChaptersModel::setStatus(ChaptersModel::Status status)
{
    m_status = status;
    emit statusChanged();
}

QHash<int, QByteArray> ChaptersModel::roleNames() const
{
    static const QHash<int, QByteArray> roles {
        { IdRole, "id" },
        { TitleRole, "title" },
        { DateRole, "date" },
        { NumberRole, "number" },
        { SelectedRole, "selected" },
        { ProgressRole, "progress" },
        { ReadRole, "read" },
        { QueuedRole, "queued" },
        { RecentlyAdded, "recentlyAdded" }
    };
    return roles;
}
