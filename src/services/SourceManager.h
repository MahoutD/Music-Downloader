#ifndef SOURCEMANAGER_H
#define SOURCEMANAGER_H

#include <QObject>
#include <QString>
#include <QList>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkAccessManager>
#include "../models/SongItem.h"

struct AudioSourceItem {
    QString id;
    QString name;
    QString type; // "builtin" or "custom"
    bool enabled = true;
    int platform = 0; // PlatformType
    QString description;
    QString api;
    int priority = 1;
    QString status = "ok"; // "ok", "fail", "testing", "untested"
    int latencyMs = 35;
    QString statusText = "可用";

    QJsonObject toJson() const {
        QJsonObject obj;
        obj["id"] = id;
        obj["name"] = name;
        obj["type"] = type;
        obj["enabled"] = enabled;
        obj["platform"] = platform;
        obj["description"] = description;
        obj["api"] = api;
        obj["priority"] = priority;
        return obj;
    }

    static AudioSourceItem fromJson(const QJsonObject &obj) {
        AudioSourceItem item;
        item.id = obj.value("id").toString();
        item.name = obj.value("name").toString();
        item.type = obj.value("type").toString("custom");
        item.enabled = obj.value("enabled").toBool(true);
        item.platform = obj.value("platform").toInt(0);
        item.description = obj.value("description").toString();
        item.api = obj.value("api").toString();
        item.priority = obj.value("priority").toInt(1);
        item.status = "ok";
        item.statusText = "可用";
        return item;
    }

    QVariantMap toMap() const {
        QVariantMap map;
        map["id"] = id;
        map["name"] = name;
        map["type"] = type;
        map["enabled"] = enabled;
        map["platform"] = platform;
        map["description"] = description;
        map["api"] = api;
        map["priority"] = priority;
        map["status"] = status;
        map["latencyMs"] = latencyMs;
        map["statusText"] = statusText;
        return map;
    }
};

class SourceManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentSourceId READ currentSourceId WRITE setCurrentSourceId NOTIFY currentSourceIdChanged)

public:
    explicit SourceManager(QObject *parent = nullptr);

    QString currentSourceId() const { return m_currentSourceId; }
    void setCurrentSourceId(const QString &id) {
        if (m_currentSourceId != id) {
            m_currentSourceId = id;
            saveSources();
            emit currentSourceIdChanged();
        }
    }

    QList<AudioSourceItem> sources() const { return m_sources; }
    QVariantList getSourcesVariant() const;

    bool isPlatformEnabled(PlatformType platform) const;

    Q_INVOKABLE bool exportSources(const QString &filePath);
    Q_INVOKABLE bool importSources(const QString &filePath);
    Q_INVOKABLE void resetDefaultSources();
    Q_INVOKABLE void updateDefaultSources();
    Q_INVOKABLE void toggleSource(const QString &id, bool enabled);
    Q_INVOKABLE void testSource(const QString &id);
    Q_INVOKABLE void testAllSources();
    void loadSources();
    void saveSources();

signals:
    void sourcesChanged();
    void currentSourceIdChanged();
    void errorOccurred(const QString &message);
    void message(const QString &msg);
    void sourceTested(const QString &id, bool ok, int latencyMs, const QString &statusText);

private:
    QString m_currentSourceId = "all";
    QList<AudioSourceItem> m_sources;
    QNetworkAccessManager *m_nam;

    QString configFilePath() const;
    QList<AudioSourceItem> defaultSources() const;
};

#endif // SOURCEMANAGER_H
