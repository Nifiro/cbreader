#include "asyncimageprovider.h"
#include "asyncimageresponse.h"

QQuickImageResponse *AsyncImageProvider::requestImageResponse(const QString &id, const QSize &requestedSize)
{
    AsyncImageResponse *response = new AsyncImageResponse(id, requestedSize);
    response->loadThumbnail();
    return response;
}
