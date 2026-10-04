#ifndef IMUSICPROVIDER_H
#define IMUSICPROVIDER_H

#include <QString>
#include <QStringList>
#include <QList>
#include <functional>
#include "../models/SongItem.h"

struct ChartInfo {
    QString id;
    QString name;
    QString description;
};

class IMusicProvider {
public:
    virtual ~IMusicProvider() = default;

    virtual PlatformType platform() const = 0;
    virtual QString platformName() const = 0;

    virtual void search(const QString &keyword, int page, int pageSize,
                        std::function<void(bool success, const QList<SongItem> &songs, int total)> callback) = 0;

    virtual void getHotSearch(std::function<void(const QStringList &hotWords)> callback) = 0;

    virtual QList<ChartInfo> getChartList() = 0;

    virtual void getChartSongs(const QString &chartId, int page, int pageSize,
                               std::function<void(bool success, const QList<SongItem> &songs)> callback) = 0;

    virtual void resolveAudioUrl(const SongItem &song, QualityType quality,
                                 std::function<void(bool success, const QString &url, const QString &ext)> callback) = 0;

    virtual void getLyric(const SongItem &song,
                          std::function<void(bool success, const QString &lrc)> callback) = 0;

    virtual void getCoverUrl(const SongItem &song,
                             std::function<void(bool success, const QString &coverUrl)> callback) = 0;
};

#endif // IMUSICPROVIDER_H
