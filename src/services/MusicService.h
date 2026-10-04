#ifndef MUSICSERVICE_H
#define MUSICSERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QMap>
#include <memory>
#include "IMusicProvider.h"
#include "KuwoProvider.h"
#include "KuGouProvider.h"
#include "NetEaseProvider.h"
#include "QQMusicProvider.h"

class SourceManager;

class MusicService : public QObject {
    Q_OBJECT
public:
    explicit MusicService(QObject *parent = nullptr);
    ~MusicService();

    void setSourceManager(SourceManager *sourceManager) { m_sourceManager = sourceManager; }
    SourceManager* sourceManager() const { return m_sourceManager; }

    void search(const QString &keyword, PlatformType platform, int page, int pageSize,
                std::function<void(bool success, const QList<SongItem> &songs, int total)> callback);

    void getHotSearch(PlatformType platform, std::function<void(const QStringList &hotWords)> callback);

    QList<ChartInfo> getChartList(PlatformType platform);

    void getChartSongs(PlatformType platform, const QString &chartId, int page, int pageSize,
                       std::function<void(bool success, const QList<SongItem> &songs)> callback);

    void resolveAudioUrl(const SongItem &song, QualityType quality,
                         std::function<void(bool success, const QString &url, const QString &ext)> callback);

    void getLyric(const SongItem &song,
                  std::function<void(bool success, const QString &lrc)> callback);

    void getCoverUrl(const SongItem &song,
                     std::function<void(bool success, const QString &coverUrl)> callback);

    QNetworkAccessManager* networkAccessManager() { return m_nam; }

private:
    QNetworkAccessManager *m_nam;
    QMap<PlatformType, std::shared_ptr<IMusicProvider>> m_providers;
    SourceManager *m_sourceManager = nullptr;

    void fallbackResolve(const SongItem &song, QualityType quality,
                         std::function<void(bool success, const QString &url, const QString &ext)> callback);
};

#endif // MUSICSERVICE_H
