#include "directory.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QtDebug>

#include <memory>

Directory::Directory()
{
}

Directory::~Directory()
{
}

bool Directory::open(const QString &dirName)
{
    m_dir = dirName;
    QFileInfo dirTest(dirName);
    return dirTest.isDir() && dirTest.isReadable();
}

QStringList Directory::recurseDir(const QString &dirPath, const QString &prefix, int curDepth) const
{
    QDir dir(dirPath + prefix);
    QMimeDatabase db;
    dir.setFilter(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot);
    QStringList fileList;
    QDirIterator it(dir);
    QFileInfo info;
    while(it.hasNext())
    {
        it.next();
        info = it.fileInfo();
        if (info.isDir() && curDepth < staticMaxDepth)
            fileList.append(recurseDir( dirPath, info.fileName() + QStringLiteral("/"), curDepth + 1));
        else if (info.isFile() && db.mimeTypeForFile(info.filePath()).name().startsWith("image"))
            fileList.append(prefix + info.fileName());
    }
    return fileList;
}

QStringList Directory::list() const
{
    return recurseDir( m_dir, QStringLiteral(""), 0 );
}
