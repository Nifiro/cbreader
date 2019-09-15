#ifndef DIRECTORY_H
#define DIRECTORY_H

#include <QString>

class QIODevice;

class Directory
{
public:
    explicit Directory();
    ~Directory();

    bool open(const QString &fileName);
    QStringList list() const;

private:
    QStringList recurseDir(const QString &dir, const QString &prefix, int curDepth) const;

    static const int staticMaxDepth = 1;
    QString m_dir;
};

#endif // DIRECTORY_H
