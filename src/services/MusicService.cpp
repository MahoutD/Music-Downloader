#include "MusicService.h"
#include "SourceManager.h"
#include <QSet>
#include <QDebug>

MusicService::MusicService(QObject *parent)
    : QObject(parent), m_nam(new QNetworkAccessManager(this)) {
    m_providers[PlatformType::NetEase] = std::make_shared<NetEaseProvider>(m_nam, this);
    m_providers[PlatformType::QQMusic] = std::make_shared<QQMusicProvider>(m_nam, this);
    m_providers[PlatformType::KuGou] = std::make_shared<KuGouProvider>(m_nam, this);
    m_providers[PlatformType::Kuwo] = std::make_shared<KuwoProvider>(m_nam, this);
}

MusicService::~MusicService() = default;

void MusicService::search(const QString &keyword, PlatformType platform, int page, int pageSize,
                          std::function<void(bool success, const QList<SongItem> &songs, int total)> callback) {
    if (platform != PlatformType::Aggregated) {
        if (m_providers.contains(platform)) {
            m_providers[platform]->search(keyword, page, pageSize, callback);
            return;
        }
        callback(false, {}, 0);
        return;
    }

    // Check if a specific sound source is selected from SourceManager
    if (m_sourceManager && !m_sourceManager->currentSourceId().isEmpty() && m_sourceManager->currentSourceId() != "all") {
        QString selId = m_sourceManager->currentSourceId();
        for (const auto &item : m_sourceManager->sources()) {
            if (item.id == selId && item.enabled) {
                PlatformType p = static_cast<PlatformType>(item.platform);
                if (m_providers.contains(p)) {
                    m_providers[p]->search(keyword, page, pageSize, callback);
                    return;
                }
            }
        }
    }

    // Aggregated search across all 4 platforms
    struct AggContext {
        int pending = 4;
        QList<SongItem> allSongs;
        int totalSum = 0;
        bool anySuccess = false;
    };
    auto ctx = std::make_shared<AggContext>();

    int perPlatformLimit = qMax(5, pageSize / 4 + 2);

    for (auto it = m_providers.begin(); it != m_providers.end(); ++it) {
        auto prov = it.value();
        prov->search(keyword, page, perPlatformLimit, [ctx, callback](bool ok, const QList<SongItem> &songs, int total) {
            ctx->pending--;
            if (ok) {
                ctx->anySuccess = true;
                ctx->allSongs.append(songs);
                ctx->totalSum += total;
            }

            if (ctx->pending == 0) {
                // Interleave or keep results
                callback(ctx->anySuccess, ctx->allSongs, ctx->totalSum);
            }
        });
    }
}

void MusicService::getHotSearch(PlatformType platform, std::function<void(const QStringList &hotWords)> callback) {
    if (platform != PlatformType::Aggregated) {
        if (m_providers.contains(platform)) {
            m_providers[platform]->getHotSearch(callback);
            return;
        }
        callback({"海阔天空", "晴天", "起风了", "周杰伦", "林俊杰", "陈奕迅"});
        return;
    }

    // Aggregated hot words
    struct HotContext {
        int pending = 4;
        QStringList merged;
        QSet<QString> seen;
    };
    auto ctx = std::make_shared<HotContext>();

    for (auto it = m_providers.begin(); it != m_providers.end(); ++it) {
        it.value()->getHotSearch([ctx, callback](const QStringList &words) {
            ctx->pending--;
            for (const auto &w : words) {
                if (!ctx->seen.contains(w) && ctx->merged.size() < 20) {
                    ctx->seen.insert(w);
                    ctx->merged.append(w);
                }
            }
            if (ctx->pending == 0) {
                if (ctx->merged.isEmpty()) {
                    ctx->merged = {"海阔天空", "晴天", "起风了", "周杰伦", "林俊杰", "陈奕迅", "邓紫棋"};
                }
                callback(ctx->merged);
            }
        });
    }
}

QList<ChartInfo> MusicService::getChartList(PlatformType platform) {
    if (platform == PlatformType::Aggregated) {
        // Return popular mix of top charts
        return {
            {"kw_16", "酷我热歌榜", "酷我平台最热播放排行榜"},
            {"kg_8888", "酷狗TOP500", "酷狗全网收听排行TOP500"},
            {"wy_3778678", "网易热歌榜", "网易云音乐播放量TOP100"},
            {"qq_26", "QQ热歌榜", "QQ音乐巅峰流行热歌榜"}
        };
    }

    if (m_providers.contains(platform)) {
        return m_providers[platform]->getChartList();
    }
    return {};
}

void MusicService::getChartSongs(PlatformType platform, const QString &chartId, int page, int pageSize,
                                 std::function<void(bool success, const QList<SongItem> &songs)> callback) {
    if (platform == PlatformType::Aggregated) {
        if (chartId.startsWith("kw_")) {
            m_providers[PlatformType::Kuwo]->getChartSongs(chartId.mid(3), page, pageSize, callback);
        } else if (chartId.startsWith("kg_")) {
            m_providers[PlatformType::KuGou]->getChartSongs(chartId.mid(3), page, pageSize, callback);
        } else if (chartId.startsWith("wy_")) {
            m_providers[PlatformType::NetEase]->getChartSongs(chartId.mid(3), page, pageSize, callback);
        } else if (chartId.startsWith("qq_")) {
            m_providers[PlatformType::QQMusic]->getChartSongs(chartId.mid(3), page, pageSize, callback);
        } else {
            m_providers[PlatformType::Kuwo]->getChartSongs("16", page, pageSize, callback);
        }
        return;
    }

    if (m_providers.contains(platform)) {
        m_providers[platform]->getChartSongs(chartId, page, pageSize, callback);
        return;
    }
    callback(false, {});
}

void MusicService::resolveAudioUrl(const SongItem &song, QualityType quality,
                                   std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    // If a specific sound source is selected from SourceManager, prioritize it
    if (m_sourceManager && !m_sourceManager->currentSourceId().isEmpty() && m_sourceManager->currentSourceId() != "all") {
        QString selId = m_sourceManager->currentSourceId();
        for (const auto &item : m_sourceManager->sources()) {
            if (item.id == selId && item.enabled) {
                PlatformType p = static_cast<PlatformType>(item.platform);
                if (m_providers.contains(p)) {
                    m_providers[p]->resolveAudioUrl(song, quality, [this, song, quality, callback](bool ok, const QString &url, const QString &ext) {
                        if (ok && !url.isEmpty()) {
                            callback(true, url, ext);
                        } else {
                            fallbackResolve(song, quality, callback);
                        }
                    });
                    return;
                }
            }
        }
    }

    if (!m_providers.contains(song.platform)) {
        fallbackResolve(song, quality, callback);
        return;
    }

    // Try original platform
    m_providers[song.platform]->resolveAudioUrl(song, quality, [this, song, quality, callback](bool ok, const QString &url, const QString &ext) {
        if (ok && !url.isEmpty()) {
            callback(true, url, ext);
        } else {
            // Intelligent cross-platform fallback!
            qDebug() << "Native resolve failed for:" << song.title << song.artist << ", attempting fallback match...";
            fallbackResolve(song, quality, callback);
        }
    });
}

void MusicService::fallbackResolve(const SongItem &song, QualityType quality,
                                   std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    QString query = song.title;
    if (!song.artist.isEmpty()) {
        query += " " + song.artist.split("/")[0].trimmed();
    }

    // Determine fallback priority: Kuwo has full VIP mobile car resolution, prioritize it!
    QList<PlatformType> fallbackOrder;
    if (song.platform == PlatformType::Kuwo) {
        fallbackOrder = {PlatformType::KuGou, PlatformType::QQMusic, PlatformType::NetEase};
    } else {
        fallbackOrder = {PlatformType::Kuwo, PlatformType::KuGou, PlatformType::QQMusic, PlatformType::NetEase};
        fallbackOrder.removeAll(song.platform);
    }

    auto tryNext = std::make_shared<std::function<void(int)>>();
    *tryNext = [this, fallbackOrder, query, song, quality, callback, tryNext](int index) {
        if (index >= fallbackOrder.size()) {
            callback(false, "", "");
            return;
        }

        PlatformType p = fallbackOrder[index];
        if (!m_providers.contains(p)) {
            (*tryNext)(index + 1);
            return;
        }

        auto prov = m_providers[p];
        prov->search(query, 1, 5, [prov, song, quality, callback, tryNext, index](bool ok, const QList<SongItem> &songs, int) {
            if (ok && !songs.isEmpty()) {
                // Find best matching song
                SongItem bestSong = songs[0];
                int bestScore = -1;
                for (const auto &item : songs) {
                    int score = 0;
                    if (item.title.contains(song.title, Qt::CaseInsensitive) || song.title.contains(item.title, Qt::CaseInsensitive)) {
                        score += 10;
                    }
                    if (!song.artist.isEmpty() && (item.artist.contains(song.artist, Qt::CaseInsensitive) || song.artist.contains(item.artist, Qt::CaseInsensitive))) {
                        score += 20;
                    }
                    if (score > bestScore) {
                        bestScore = score;
                        bestSong = item;
                    }
                }

                prov->resolveAudioUrl(bestSong, quality, [callback, tryNext, index](bool resOk, const QString &url, const QString &ext) {
                    if (resOk && !url.isEmpty()) {
                        callback(true, url, ext);
                    } else {
                        (*tryNext)(index + 1);
                    }
                });
            } else {
                (*tryNext)(index + 1);
            }
        });
    };

    (*tryNext)(0);
}

void MusicService::getLyric(const SongItem &song,
                            std::function<void(bool success, const QString &lrc)> callback) {
    if (m_providers.contains(song.platform)) {
        m_providers[song.platform]->getLyric(song, [this, song, callback](bool ok, const QString &lrc) {
            if (ok && !lrc.isEmpty()) {
                callback(true, lrc);
            } else {
                // Cross-source lyric fallback
                QString query = song.title + " " + song.artist;
                m_providers[PlatformType::KuGou]->search(query, 1, 2, [this, callback](bool sOk, const QList<SongItem> &songs, int) {
                    if (sOk && !songs.isEmpty()) {
                        m_providers[PlatformType::KuGou]->getLyric(songs[0], callback);
                    } else {
                        callback(false, "");
                    }
                });
            }
        });
        return;
    }
    callback(false, "");
}

void MusicService::getCoverUrl(const SongItem &song,
                               std::function<void(bool success, const QString &coverUrl)> callback) {
    if (!song.coverUrl.isEmpty()) {
        callback(true, song.coverUrl);
        return;
    }

    if (m_providers.contains(song.platform)) {
        m_providers[song.platform]->getCoverUrl(song, callback);
        return;
    }
    callback(false, "");
}
