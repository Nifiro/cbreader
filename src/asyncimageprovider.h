#ifndef ASYNCIMAGEPROVIDER_H
#define ASYNCIMAGEPROVIDER_H

#include <QQuickAsyncImageProvider>

/*!
 * \brief The AsyncImageProvider class
 * \file asyncimageprovider.h
 */
class AsyncImageProvider : public QQuickAsyncImageProvider
{
public:
    /*!
     * \brief requestImageResponse image returned form this shit
     * \param id
     * \param requestedSize
     * \return
     */
    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;
};

#endif // ASYNCIMAGEPROVIDER_H
