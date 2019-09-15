#ifndef UNRAR_H
#define UNRAR_H

#include "document.h"

#include <QObject>
#include <QString>
#include <QProcess>
#include <QByteArray>
#include <QStringList>
#include <QTemporaryDir>

class Unrar : public QObject
{
    Q_OBJECT
public:
    explicit Unrar(QObject *parent = nullptr);
    ~Unrar();
#ifdef USE_UNRAR_EXE
    bool open(const QString &fileName, Document::OpenMode mode);
    QByteArray contentOf(const QString &fileName);
    QStringList list();
    QString path() const;

private slots:
    void readFromStdout();
    void readFromStderr();

private:
    int startSyncProcess(const QStringList &args);

    QProcess *mProcess;
    QString mFileName;
    QByteArray mStdOutData;
    QByteArray mStdErrData;
    QTemporaryDir *mTempDir;
    QString mPath;
#else
    bool open(QString fileName, Document::OpenMode mode);
    QStringList list();
    void extractAll(QString path);
    void extractFirstPage();
    QString path();
    QImage pageImage(int page);
    QString firstPagePath() const;

private:
    QString m_fileName;
    QString m_path;
    QString m_firstPagePath;
    QStringList m_entries;
    QStringList m_directories;
    QTemporaryDir *m_tempDir;
#endif
};

#endif // UNRAR_H
