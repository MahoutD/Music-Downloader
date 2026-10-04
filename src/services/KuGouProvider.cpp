#include "KuGouProvider.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QUrlQuery>
#include <QByteArray>

KuGouProvider::KuGouProvider(QNetworkAccessManager *nam, QObject *parent)
    : QObject(parent), m_nam(nam) {}

void KuGouProvider::search(const QString &keyword, int page, int pageSize,
                           std::function<void(bool success, const QList<SongItem> &songs, int total)> callback) {
    QString urlStr = QString("http://mobilecdn.kugou.com/api/v3/search/song?format=json&keyword=%1&page=%2&pagesize=%3&showtype=1")
                         .arg(QUrl::toPercentEncoding(keyword), QString::number(page), QString::number(pageSize));

    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

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
        QJsonObject data = root.value("data").toObject();
        int total = data.value("total").toInt();
        QJsonArray info = data.value("info").toArray();

        QList<SongItem> songs;
        for (const auto &val : info) {
            QJsonObject obj = val.toObject();
            SongItem song;
            song.id = obj.value("hash").toString();
            song.title = obj.value("songname").toString();
            song.artist = obj.value("singername").toString();
            song.album = obj.value("album_name").toString();
            song.duration = obj.value("duration").toInt();
            song.platform = PlatformType::KuGou;
            song.extra = obj;

            QString cover = obj.value("trans_param").toObject().value("union_cover").toString();
            if (cover.isEmpty()) cover = obj.value("album_sizable_cover").toString();
            if (cover.isEmpty()) cover = obj.value("imgurl").toString();
            if (!cover.isEmpty()) {
                cover.replace("{size}", "400");
                song.coverUrl = cover;
            }

            if (!song.id.isEmpty() && !song.title.isEmpty()) {
                songs.append(song);
            }
        }
        callback(true, songs, total > 0 ? total : songs.size());
    });
}

void KuGouProvider::getHotSearch(std::function<void(const QStringList &hotWords)> callback) {
    QString urlStr = "http://mobilecdn.kugou.com/api/v3/search/hot?format=json&plat=0&count=20";
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback({"白月光与朱砂痣", "句号", "乌梅子酱", "周杰伦", "海阔天空", "晴天", "罗刹海市"});
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray info = doc.object().value("data").toObject().value("info").toArray();
        QStringList words;
        for (const auto &val : info) {
            QString kw = val.toObject().value("keyword").toString().trimmed();
            if (!kw.isEmpty() && !words.contains(kw)) {
                words.append(kw);
            }
        }
        if (words.isEmpty()) {
            words = {"白月光与朱砂痣", "句号", "乌梅子酱", "周杰伦", "海阔天空", "晴天", "罗刹海市"};
        }
        callback(words);
    });
}

QList<ChartInfo> KuGouProvider::getChartList() {
    return {
        {"8888", "酷狗TOP500", "酷狗全平台收听综合排名前500名"},
        {"6666", "酷狗飙升榜", "全网播放热度激增飙升榜单"},
        {"23784", "华语新歌榜", "最新发布的华语流行新歌排行榜"},
        {"24971", "热歌榜", "当期持续火爆的流行热歌精选"},
        {"31308", "网络红歌榜", "互联网短视频流行网络神曲"}
    };
}

void KuGouProvider::getChartSongs(const QString &chartId, int page, int pageSize,
                                 std::function<void(bool success, const QList<SongItem> &songs)> callback) {
    QString urlStr = QString("http://mobilecdn.kugou.com/api/v3/rank/song?rankid=%1&page=%2&pagesize=%3")
                         .arg(chartId, QString::number(page), QString::number(pageSize));

    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback(false, {});
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray info = doc.object().value("data").toObject().value("info").toArray();
        QList<SongItem> songs;
        for (const auto &val : info) {
            QJsonObject obj = val.toObject();
            SongItem song;
            song.id = obj.value("hash").toString();
            // In rank list, Kugou often puts "Singer - SongName" in filename or songname
            QString songName = obj.value("songname").toString();
            QString singerName = obj.value("singername").toString();
            if (singerName.isEmpty() && songName.contains(" - ")) {
                auto parts = songName.split(" - ");
                singerName = parts[0].trimmed();
                songName = parts.mid(1).join(" - ").trimmed();
            }
            song.title = songName;
            song.artist = singerName;
            song.album = obj.value("album_name").toString();
            song.duration = obj.value("duration").toInt();
            song.platform = PlatformType::KuGou;
            song.extra = obj;

            QString cover = obj.value("trans_param").toObject().value("union_cover").toString();
            if (cover.isEmpty()) cover = obj.value("album_sizable_cover").toString();
            if (cover.isEmpty()) cover = obj.value("imgurl").toString();
            if (!cover.isEmpty()) {
                cover.replace("{size}", "400");
                song.coverUrl = cover;
            }

            if (!song.id.isEmpty() && !song.title.isEmpty()) {
                songs.append(song);
            }
        }
        callback(true, songs);
    });
}

void KuGouProvider::resolveAudioUrl(const SongItem &song, QualityType quality,
                                    std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    resolveNativeAudioUrl(song, quality, callback);
}

void KuGouProvider::resolveNativeAudioUrl(const SongItem &song, QualityType quality,
                                          std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    QString targetHash = song.id;

    // Check if extra has 320hash or sqhash
    QJsonObject extra = song.extra;
    QJsonObject extraSub = extra.value("extra").toObject();

    if (quality == QualityType::Lossless_FLAC) {
        QString sq = extraSub.value("sqhash").toString();
        if (sq.isEmpty()) sq = extra.value("sqhash").toString();
        if (!sq.isEmpty()) targetHash = sq;
    } else if (quality == QualityType::High_320k) {
        QString h320 = extraSub.value("320hash").toString();
        if (h320.isEmpty()) h320 = extra.value("320hash").toString();
        if (!h320.isEmpty()) targetHash = h320;
    }

    auto fetchPlayInfo = [this, song, quality, callback](const QString &hashToUse, bool canRetry) {
        QString urlStr = QString("http://m.kugou.com/app/i/getSongInfo.php?cmd=playInfo&hash=%1").arg(hashToUse);
        QNetworkRequest req{QUrl(urlStr)};
        req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

        QNetworkReply *reply = m_nam->get(req);
        connect(reply, &QNetworkReply::finished, [this, reply, song, hashToUse, canRetry, callback]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) {
                if (canRetry && hashToUse != song.id) {
                    resolveNativeAudioUrl(song, QualityType::Standard_128k, callback);
                } else {
                    callback(false, "", "");
                }
                return;
            }

            QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            QJsonObject obj = doc.object();
            QString playUrl = obj.value("url").toString();
            if (playUrl.isEmpty()) {
                QJsonArray backups = obj.value("backup_url").toArray();
                if (!backups.isEmpty()) {
                    playUrl = backups[0].toString();
                }
            }

            if (!playUrl.isEmpty()) {
                QString ext = obj.value("extName").toString();
                if (ext.isEmpty()) {
                    ext = playUrl.endsWith(".flac", Qt::CaseInsensitive) ? "flac" : "mp3";
                }
                callback(true, playUrl, ext);
            } else {
                if (canRetry && hashToUse != song.id) {
                    resolveNativeAudioUrl(song, QualityType::Standard_128k, callback);
                } else {
                    callback(false, "", "");
                }
            }
        });
    };

    fetchPlayInfo(targetHash, targetHash != song.id);
}

void KuGouProvider::getLyric(const SongItem &song,
                             std::function<void(bool success, const QString &lrc)> callback) {
    QString urlStr = QString("http://krcs.kugou.com/search?ver=1&man=yes&client=mobi&keyword=&duration=&hash=%1").arg(song.id);
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [this, reply, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback(false, "");
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray candidates = doc.object().value("candidates").toArray();
        if (candidates.isEmpty()) {
            callback(false, "");
            return;
        }

        QJsonObject first = candidates[0].toObject();
        QString id = first.value("id").toString();
        QString accesskey = first.value("accesskey").toString();

        QString dlUrl = QString("http://krcs.kugou.com/download?ver=1&client=mobi&id=%1&accesskey=%2&fmt=lrc&charset=utf8")
                            .arg(id, accesskey);
        QNetworkRequest dlReq{QUrl(dlUrl)};
        dlReq.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

        QNetworkReply *dlReply = m_nam->get(dlReq);
        connect(dlReply, &QNetworkReply::finished, [dlReply, callback]() {
            dlReply->deleteLater();
            if (dlReply->error() != QNetworkReply::NoError) {
                callback(false, "");
                return;
            }

            QJsonDocument dlDoc = QJsonDocument::fromJson(dlReply->readAll());
            QString base64 = dlDoc.object().value("content").toString();
            if (base64.isEmpty()) {
                callback(false, "");
                return;
            }

            QByteArray decoded = QByteArray::fromBase64(base64.toUtf8());
            callback(true, QString::fromUtf8(decoded));
        });
    });
}

void KuGouProvider::getCoverUrl(const SongItem &song,
                                std::function<void(bool success, const QString &coverUrl)> callback) {
    if (!song.coverUrl.isEmpty()) {
        callback(true, song.coverUrl);
        return;
    }

    QString urlStr = QString("http://m.kugou.com/app/i/getSongInfo.php?cmd=playInfo&hash=%1").arg(song.id);
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            QJsonObject obj = doc.object();
            QString img = obj.value("album_img").toString();
            if (img.isEmpty()) img = obj.value("imgUrl").toString();
            if (!img.isEmpty()) {
                img.replace("{size}", "400");
                callback(true, img);
                return;
            }
        }
        callback(false, "");
    });
}
