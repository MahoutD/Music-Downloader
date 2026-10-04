#include "NetEaseProvider.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QUrlQuery>

NetEaseProvider::NetEaseProvider(QNetworkAccessManager *nam, QObject *parent)
    : QObject(parent), m_nam(nam) {}

void NetEaseProvider::search(const QString &keyword, int page, int pageSize,
                             std::function<void(bool success, const QList<SongItem> &songs, int total)> callback) {
    int offset = qMax(0, (page - 1) * pageSize);
    QString urlStr = QString("https://music.163.com/api/search/get/web?s=%1&type=1&offset=%2&total=true&limit=%3")
                         .arg(QUrl::toPercentEncoding(keyword), QString::number(offset), QString::number(pageSize));

    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setRawHeader("Referer", "https://music.163.com");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback(false, {}, 0);
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) {
            callback(false, {}, 0);
            return;
        }

        QJsonObject root = doc.object();
        QJsonObject result = root.value("result").toObject();
        int total = result.value("songCount").toInt();
        QJsonArray songsArr = result.value("songs").toArray();

        QList<SongItem> songs;
        for (const auto &val : songsArr) {
            QJsonObject obj = val.toObject();
            SongItem song;
            song.id = QString::number(obj.value("id").toInteger());
            song.title = obj.value("name").toString();

            // Artists
            QJsonArray artists = obj.value("artists").toArray();
            QStringList artistNames;
            for (const auto &art : artists) {
                artistNames.append(art.toObject().value("name").toString());
            }
            song.artist = artistNames.join(" / ");

            // Album
            QJsonObject albumObj = obj.value("album").toObject();
            song.album = albumObj.value("name").toString();
            QString picUrl = albumObj.value("picUrl").toString();
            if (picUrl.isEmpty()) {
                picUrl = albumObj.value("artist").toObject().value("img1v1Url").toString();
            }
            if (picUrl.isEmpty() && !artists.isEmpty()) {
                picUrl = artists[0].toObject().value("img1v1Url").toString();
            }
            song.coverUrl = picUrl;
            song.duration = obj.value("duration").toInt() / 1000;
            song.platform = PlatformType::NetEase;
            song.extra = obj;

            if (!song.id.isEmpty() && !song.title.isEmpty()) {
                songs.append(song);
            }
        }
        callback(true, songs, total > 0 ? total : songs.size());
    });
}

void NetEaseProvider::getHotSearch(std::function<void(const QStringList &hotWords)> callback) {
    getChartSongs("3778678", 1, 15, [callback](bool ok, const QList<SongItem> &songs) {
        if (ok && !songs.isEmpty()) {
            QStringList words;
            for (const auto &s : songs) {
                if (!s.title.isEmpty() && !words.contains(s.title)) {
                    words.append(s.title);
                }
                if (words.size() >= 10) break;
            }
            callback(words);
        } else {
            callback({"我记得", "悬溺", "若月亮没来", "向云端", "奢香夫人", "爱如火", "海阔天空", "晴天"});
        }
    });
}

QList<ChartInfo> NetEaseProvider::getChartList() {
    return {
        {"3778678", "网易热歌榜", "网易云音乐当前播放量最高的100首热门歌曲"},
        {"19723756", "网易飙升榜", "100首近期播放热度与分享量飙升最快的歌曲"},
        {"3779629", "网易新歌榜", "每日更新近期上架的华语及全球热门新歌"},
        {"2884035", "原创歌曲榜", "展现中国原创音乐力量的优秀独立歌曲榜单"}
    };
}

void NetEaseProvider::getChartSongs(const QString &chartId, int page, int pageSize,
                                   std::function<void(bool success, const QList<SongItem> &songs)> callback) {
    QString urlStr = QString("https://music.163.com/api/playlist/detail?id=%1").arg(chartId);
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setRawHeader("Referer", "https://music.163.com");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, page, pageSize, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback(false, {});
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) {
            callback(false, {});
            return;
        }

        QJsonObject root = doc.object();
        QJsonObject result = root.value("result").toObject();
        QJsonArray tracks = result.value("tracks").toArray();

        int startIdx = qMax(0, (page - 1) * pageSize);
        int endIdx = qMin(tracks.size(), startIdx + pageSize);

        QList<SongItem> songs;
        for (int i = startIdx; i < endIdx; ++i) {
            QJsonObject obj = tracks[i].toObject();
            SongItem song;
            song.id = QString::number(obj.value("id").toInteger());
            song.title = obj.value("name").toString();

            QJsonArray artists = obj.value("artists").toArray();
            QStringList artistNames;
            for (const auto &art : artists) {
                artistNames.append(art.toObject().value("name").toString());
            }
            song.artist = artistNames.join(" / ");

            QJsonObject albumObj = obj.value("album").toObject();
            song.album = albumObj.value("name").toString();
            QString picUrl = albumObj.value("picUrl").toString();
            if (picUrl.isEmpty()) {
                picUrl = albumObj.value("artist").toObject().value("img1v1Url").toString();
            }
            if (picUrl.isEmpty() && !artists.isEmpty()) {
                picUrl = artists[0].toObject().value("img1v1Url").toString();
            }
            song.coverUrl = picUrl;
            song.duration = obj.value("duration").toInt() / 1000;
            song.platform = PlatformType::NetEase;
            song.extra = obj;

            if (!song.id.isEmpty() && !song.title.isEmpty()) {
                songs.append(song);
            }
        }
        callback(true, songs);
    });
}

void NetEaseProvider::resolveAudioUrl(const SongItem &song, QualityType quality,
                                       std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    resolveNativeAudioUrl(song, quality, callback);
}

void NetEaseProvider::resolveNativeAudioUrl(const SongItem &song, QualityType quality,
                                            std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    Q_UNUSED(quality)
    // 1. Try Meting proxy API which resolves and redirects to high quality stream
    QString metingUrl = QString("https://api.injahow.cn/meting/?server=netease&type=url&id=%1").arg(song.id);
    QNetworkRequest metingReq{QUrl(metingUrl)};
    metingReq.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    metingReq.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);

    QNetworkReply *metingReply = m_nam->get(metingReq);
    connect(metingReply, &QNetworkReply::finished, [this, metingReply, song, callback]() {
        metingReply->deleteLater();
        int statusCode = metingReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        QUrl redirectUrl = metingReply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();

        if ((statusCode == 301 || statusCode == 302 || statusCode == 307) && !redirectUrl.isEmpty()) {
            QString resolved = redirectUrl.toString();
            if (!resolved.contains("404")) {
                callback(true, resolved, "mp3");
                return;
            }
        }

        // 2. Fallback to direct outer url
        QString outerUrl = QString("https://music.163.com/song/media/outer/url?id=%1.mp3").arg(song.id);
        QNetworkRequest outerReq{QUrl(outerUrl)};
        outerReq.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
        outerReq.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);

        QNetworkReply *outerReply = m_nam->get(outerReq);
        connect(outerReply, &QNetworkReply::finished, [outerReply, callback]() {
            outerReply->deleteLater();
            int code = outerReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            QUrl outerRedir = outerReply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();

            if ((code == 301 || code == 302 || code == 307) && !outerRedir.isEmpty()) {
                QString target = outerRedir.toString();
                if (!target.contains("404")) {
                    callback(true, target, "mp3");
                    return;
                }
            }
            callback(false, "", "");
        });
    });
}

void NetEaseProvider::getLyric(const SongItem &song,
                               std::function<void(bool success, const QString &lrc)> callback) {
    QString urlStr = QString("https://music.163.com/api/song/lyric?id=%1&lv=1&kv=1&tv=-1").arg(song.id);
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setRawHeader("Referer", "https://music.163.com");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback(false, "");
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) {
            callback(false, "");
            return;
        }

        QJsonObject root = doc.object();
        QString lyric = root.value("lrc").toObject().value("lyric").toString();
        if (!lyric.isEmpty()) {
            callback(true, lyric);
        } else {
            callback(false, "");
        }
    });
}

void NetEaseProvider::getCoverUrl(const SongItem &song,
                                  std::function<void(bool success, const QString &coverUrl)> callback) {
    if (!song.coverUrl.isEmpty()) {
        callback(true, song.coverUrl);
        return;
    }

    // Try detail
    QString urlStr = QString("https://music.163.com/api/song/detail/?id=%1&ids=[%2]").arg(song.id, song.id);
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setRawHeader("Referer", "https://music.163.com");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            QJsonArray songs = doc.object().value("songs").toArray();
            if (!songs.isEmpty()) {
                QString pic = songs[0].toObject().value("album").toObject().value("picUrl").toString();
                if (!pic.isEmpty()) {
                    callback(true, pic);
                    return;
                }
            }
        }
        callback(false, "");
    });
}
