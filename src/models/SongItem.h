#ifndef SONGITEM_H
#define SONGITEM_H

#include <QString>
#include <QJsonObject>
#include <QMetaType>
#include <QIcon>

enum class PlatformType {
    Aggregated = 0,
    NetEase,
    QQMusic,
    KuGou,
    Kuwo
};

enum class QualityType {
    Standard_128k = 0,
    High_320k = 1,
    Lossless_FLAC = 2
};

struct SongItem {
    QString id;
    QString title;
    QString artist;
    QString album;
    int duration = 0; // seconds
    PlatformType platform = PlatformType::NetEase;
    QString coverUrl;
    QJsonObject extra;

    QString formattedDuration() const {
        if (duration <= 0) return "--:--";
        int m = duration / 60;
        int s = duration % 60;
        return QString("%1:%2").arg(m, 2, 10, QChar('0')).arg(s, 2, 10, QChar('0'));
    }

    QString platformName() const {
        switch (platform) {
            case PlatformType::NetEase: return "网易云";
            case PlatformType::QQMusic: return "QQ音乐";
            case PlatformType::KuGou: return "酷狗";
            case PlatformType::Kuwo: return "酷我";
            default: return "聚合";
        }
    }

    QString platformColor() const {
        switch (platform) {
            case PlatformType::NetEase: return "#e60026";
            case PlatformType::QQMusic: return "#1ecd99";
            case PlatformType::KuGou: return "#0099ff";
            case PlatformType::Kuwo: return "#ff7700";
            default: return "#8b5cf6";
        }
    }

    QString platformIconPath() const {
        return getPlatformIconPath(platform);
    }

    static QString getPlatformIconPath(PlatformType p) {
        switch (p) {
            case PlatformType::NetEase: return "qrc:/icons/netease.svg";
            case PlatformType::QQMusic: return "qrc:/icons/qq.svg";
            case PlatformType::KuGou: return "qrc:/icons/kugou.svg";
            case PlatformType::Kuwo: return "qrc:/icons/kuwo.svg";
            default: return "qrc:/icons/all.svg";
        }
    }

    QVariantMap toMap() const {
        QVariantMap map;
        map["id"] = id;
        map["title"] = title;
        map["artist"] = artist;
        map["album"] = album;
        map["duration"] = duration;
        map["formattedDuration"] = formattedDuration();
        map["platform"] = static_cast<int>(platform);
        map["platformName"] = platformName();
        map["platformColor"] = platformColor();
        map["platformIcon"] = platformIconPath();
        map["coverUrl"] = coverUrl.isEmpty() ? "qrc:/icons/app.svg" : coverUrl;
        return map;
    }

    static SongItem fromMap(const QVariantMap &map) {
        SongItem s;
        s.id = map.value("id").toString();
        s.title = map.value("title").toString();
        s.artist = map.value("artist").toString();
        s.album = map.value("album").toString();
        s.duration = map.value("duration").toInt();
        s.platform = static_cast<PlatformType>(map.value("platform").toInt());
        s.coverUrl = map.value("coverUrl").toString();
        return s;
    }
};

Q_DECLARE_METATYPE(SongItem)

#endif // SONGITEM_H
