#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <Windows.h>
#include <WinInet.h>
#include <QNetworkAccessManager>
#include <qqml.h>

class NetworkManagerAttached : public QObject
{
    Q_OBJECT

public:
    NetworkManagerAttached(QObject *object) : QObject(object) {}
    Q_INVOKABLE bool online() { return InternetGetConnectedState(nullptr, 0); }
};

class NetworkManager : public QObject
{
    Q_OBJECT

public:
    static QNetworkAccessManager *getManager()
    {
        static QNetworkAccessManager* manager = new QNetworkAccessManager();
        return manager;
    }
    static bool isOnline() { return InternetGetConnectedState(nullptr, 0); }
    static NetworkManagerAttached *qmlAttachedProperties(QObject *object)
    {
        return new NetworkManagerAttached(object);
    }

private:
    NetworkManager() {}
    NetworkManager(const NetworkManager&) = delete;
    NetworkManager(NetworkManager&&) = delete;
    NetworkManager& operator=(const NetworkManager&) = delete;
    NetworkManager& operator=(NetworkManager&&) = delete;
};

QML_DECLARE_TYPEINFO(NetworkManager, QML_HAS_ATTACHED_PROPERTIES)
#endif // NETWORKMANAGER_H
