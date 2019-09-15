#include "clipboardproxy.h"

#include <QClipboard>

ClipboardProxy::ClipboardProxy(QClipboard *clipboard) : m_clipboard(clipboard)
{
    connect(clipboard, &QClipboard::dataChanged, this, &ClipboardProxy::imageChanged);
}

QImage ClipboardProxy::image() const
{
    return m_clipboard->image();
}

void ClipboardProxy::setImage(QImage image)
{
    m_clipboard->setImage(image);
    emit imageChanged();
}
