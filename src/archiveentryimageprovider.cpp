#include <QtDebug>

#include "archiveentryimageprovider.h"
#include "document.h"

ArchiveEntryImageProvider::ArchiveEntryImageProvider() : QQuickImageProvider (QQuickImageProvider::Image)
{
}

QImage ArchiveEntryImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    int page = id.toInt();
    QImage image = Document::getDocument()->pageImage(page);
    size->setWidth(image.width());
    size->setHeight(image.height());

    if (!requestedSize.isEmpty() && requestedSize.isValid())
        return image.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    return image;
}
