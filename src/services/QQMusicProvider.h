#ifndef QQMUSICPROVIDER_H
#define QQMUSICPROVIDER_H

#include "IMusicProvider.h"
#include <QObject>
#include <QNetworkAccessManager>

class QQMusicProvider : public QObject, public IMusicProvider {
    Q_OBJECT
public:
    explicit QQMusicProvider(QNetworkAccessManager *nam, QObject *parent = nullptr);

    PlatformType platform() const override { return PlatformType::QQMusic; }
    QString platformName() const override { return "QQ音乐"; }

    void search(const QString &keyword, int page, int pageSize,
                std::function<void(bool success, const QList<SongItem> &songs, int total)> callback) override;

    void getHotSearch(std::function<void(const QStringList &hotWords)> callback) override;

    QList<ChartInfo> getChartList() override;

    void getChartSongs(const QString &chartId, int page, int pageSize,
                       std::function<void(bool success, const QList<SongItem> &songs)> callback) override;

    void resolveAudioUrl(const SongItem &song, QualityType quality,
                         std::function<void(bool success, const QString &url, const QString &ext)> callback) override;

    void getLyric(const SongItem &song,
                  std::function<void(bool success, const QString &lrc)> callback) override;

    void getCoverUrl(const SongItem &song,
                     std::function<void(bool success, const QString &coverUrl)> callback) override;

private:
    QNetworkAccessManager *m_nam;
    static QString cleanHtml(const QString &str);
    void resolveNativeAudioUrl(const SongItem &song, QualityType quality,
                               std::function<void(bool success, const QString &url, const QString &ext)> callback);
};

#endif // QQMUSICPROVIDER_H
