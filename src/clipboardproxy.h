#ifndef CLIPBOARDPROXY_H
#define CLIPBOARDPROXY_H

#include <QObject>
#include <QImage>

class QClipboard;

class ClipboardProxy : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QImage image READ image WRITE setImage NOTIFY imageChanged)

public:
    explicit ClipboardProxy(QClipboard *clipboard);

    QImage image() const;

signals:
    void imageChanged();

public slots:
    void setImage(QImage image);

private:
    QClipboard *m_clipboard;
};

#endif // CLIPBOARDPROXY_H
