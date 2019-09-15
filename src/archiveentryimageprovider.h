#ifndef ARCHIVEENTRYIMAGEPROVIDER_H
#define ARCHIVEENTRYIMAGEPROVIDER_H

#include <QQuickImageProvider>

class ArchiveEntryImageProvider : public QQuickImageProvider
{
public:
    ArchiveEntryImageProvider();

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};

#endif // ARCHIVEENTRYIMAGEPROVIDER_H
