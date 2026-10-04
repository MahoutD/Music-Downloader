#include "KuwoProvider.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QUrlQuery>
#include <QRegularExpression>

KuwoProvider::KuwoProvider(QNetworkAccessManager *nam, QObject *parent)
    : QObject(parent), m_nam(nam) {}

QString KuwoProvider::cleanHtml(const QString &str) {
    QString res = str;
    res.replace("&nbsp;", " ");
    res.replace("&amp;", "&");
    res.replace("&lt;", "<");
    res.replace("&gt;", ">");
    res.replace("&quot;", "\"");
    res.replace("&#39;", "'");
    res.remove(QRegularExpression("<[^>]*>"));
    return res.trimmed();
}

void KuwoProvider::search(const QString &keyword, int page, int pageSize,
                          std::function<void(bool success, const QList<SongItem> &songs, int total)> callback) {
    int pn = qMax(0, page - 1);
    QString urlStr = QString("https://search.kuwo.cn/r.s?client=kt&all=%1&pn=%2&rn=%3&vipver=1&ft=music&encoding=utf8&rformat=json&mobi=1")
                         .arg(QUrl::toPercentEncoding(keyword), QString::number(pn), QString::number(pageSize));

    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback(false, {}, 0);
            return;
        }

        QByteArray data = reply->readAll();
        // Kuwo r.s sometimes returns single quotes or json format
        QString str = QString::fromUtf8(data);
        str.replace('\'', '\"');
        QJsonDocument doc = QJsonDocument::fromJson(str.toUtf8());
        if (!doc.isObject()) {
            doc = QJsonDocument::fromJson(data);
        }

        if (!doc.isObject()) {
            callback(false, {}, 0);
            return;
        }

        QJsonObject root = doc.object();
        int total = root.value("TOTAL").toString().toInt();
        if (total == 0) total = root.value("TOTAL").toInt();
        QJsonArray abslist = root.value("abslist").toArray();

        QList<SongItem> songs;
        for (const auto &val : abslist) {
            QJsonObject obj = val.toObject();
            SongItem song;
            song.id = obj.value("DC_TARGETID").toString();
            if (song.id.isEmpty()) song.id = QString::number(obj.value("DC_TARGETID").toInt());
            song.title = cleanHtml(obj.value("SONGNAME").toString());
            song.artist = cleanHtml(obj.value("ARTIST").toString());
            song.album = cleanHtml(obj.value("ALBUM").toString());
            song.duration = obj.value("DURATION").toString().toInt();
            song.platform = PlatformType::Kuwo;

            // Cover URL
            QString pic = obj.value("hts_MVPIC").toString();
            if (pic.isEmpty()) {
                QString shortPic = obj.value("web_albumpic_short").toString();
                if (!shortPic.isEmpty()) {
                    pic = "https://img4.kuwo.cn/star/albumcover/" + shortPic;
                }
            }
            song.coverUrl = pic;
            song.extra = obj;

            if (!song.id.isEmpty() && !song.title.isEmpty()) {
                songs.append(song);
            }
        }

        callback(true, songs, total > 0 ? total : songs.size());
    });
}

void KuwoProvider::getHotSearch(std::function<void(const QStringList &hotWords)> callback) {
    // Fetch from hot songs chart
    getChartSongs("16", 1, 15, [callback](bool ok, const QList<SongItem> &songs) {
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
            callback({"海阔天空", "晴天", "起风了", "周杰伦", "陈奕迅", "林俊杰", "邓紫棋", "薛之谦"});
        }
    });
}

QList<ChartInfo> KuwoProvider::getChartList() {
    return {
        {"16", "酷我热歌榜", "酷我平台最热播放与下载总榜"},
        {"17", "酷我新歌榜", "每日更新的新发热门单曲"},
        {"93", "酷我飙升榜", "近期热度飙升最快的潮流金曲"},
        {"62", "抖音热歌榜", "短视频平台爆款与潮流背景音乐"},
        {"26", "经典怀旧榜", "岁月沉淀、百听不厌的经典名曲"}
    };
}

void KuwoProvider::getChartSongs(const QString &chartId, int page, int pageSize,
                                std::function<void(bool success, const QList<SongItem> &songs)> callback) {
    int pn = qMax(0, page - 1);
    QString urlStr = QString("http://kbangserver.kuwo.cn/ksong.s?from=pc&fmt=json&type=bang&data=bang&pn=%1&rn=%2&id=%3")
                         .arg(QString::number(pn), QString::number(pageSize), chartId);

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
        if (!doc.isObject()) {
            callback(false, {});
            return;
        }

        QJsonArray list = doc.object().value("musiclist").toArray();
        QList<SongItem> songs;
        for (const auto &val : list) {
            QJsonObject obj = val.toObject();
            SongItem song;
            song.id = obj.value("id").toString();
            song.title = cleanHtml(obj.value("name").toString());
            song.artist = cleanHtml(obj.value("artist").toString());
            song.album = cleanHtml(obj.value("album").toString());
            song.duration = obj.value("duration").toString().toInt();
            song.platform = PlatformType::Kuwo;
            song.coverUrl = obj.value("pic").toString();
            song.extra = obj;

            if (!song.id.isEmpty() && !song.title.isEmpty()) {
                songs.append(song);
            }
        }
        callback(true, songs);
    });
}

void KuwoProvider::resolveAudioUrl(const SongItem &song, QualityType quality,
                                   std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    QString rid = song.id;
    if (rid.startsWith("MUSIC_")) {
        rid = rid.mid(6);
    }

    QString br = "128kmp3";
    QString fmt = "mp3";
    if (quality == QualityType::Lossless_FLAC) {
        br = "2000kflac";
        fmt = "flac";
    } else if (quality == QualityType::High_320k) {
        br = "320kmp3";
        fmt = "mp3";
    }

    // Step 1: Kuwo mobile car API (supports lossless FLAC and 320k MP3 VIP audio)
    QString urlStr = QString("http://nmobi.kuwo.cn/mobi.s?user=0&source=kwplayercar_ar_6.1.0.0_B_jiakong_vh.apk&type=convert_url_with_sign&br=%1&format=%2&sig=0&rid=%3&network=WIFI&f=web")
                         .arg(br, fmt, rid);

    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "okhttp/3.10.0");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [this, reply, song, quality, rid, fmt, callback]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            QJsonObject root = doc.object();
            if (root.value("code").toInt() == 200) {
                QJsonObject data = root.value("data").toObject();
                QString audioUrl = data.value("url").toString();
                if (!audioUrl.isEmpty() && !audioUrl.startsWith("None") && (audioUrl.startsWith("http://") || audioUrl.startsWith("https://"))) {
                    QString realFmt = data.value("format").toString();
                    if (realFmt.isEmpty()) realFmt = fmt;
                    callback(true, audioUrl, realFmt);
                    return;
                }
            }
        }

        // Step 2: Fallback to anymatch car download API
        QString anymatchUrl = QString("http://anymatch.kuwo.cn/mobi.s?user=0&source=kwplayercar_ar_6.0.0.9_B_jiakong_vh.apk&type=convert_url2&br=%1&format=%2&rid=%3&network=WIFI&f=web&mode=download")
                                  .arg(quality == QualityType::Lossless_FLAC ? "2000kflac" : (quality == QualityType::High_320k ? "320kmp3" : "128kmp3"), fmt, rid);

        QNetworkRequest anyReq{QUrl(anymatchUrl)};
        anyReq.setHeader(QNetworkRequest::UserAgentHeader, "okhttp/3.10.0");

        QNetworkReply *anyReply = m_nam->get(anyReq);
        connect(anyReply, &QNetworkReply::finished, [this, anyReply, song, quality, rid, fmt, callback]() {
            anyReply->deleteLater();
            if (anyReply->error() == QNetworkReply::NoError) {
                QString text = QString::fromUtf8(anyReply->readAll());
                QString audioUrl;
                QString realFmt = fmt;
                for (const QString &line : text.split(QRegularExpression("[\r\n]+"))) {
                    int eq = line.indexOf('=');
                    if (eq > 0) {
                        QString k = line.left(eq).trimmed();
                        QString v = line.mid(eq + 1).trimmed();
                        if (k == "url") audioUrl = v;
                        else if (k == "format") realFmt = v;
                    }
                }

                if (!audioUrl.isEmpty() && !audioUrl.startsWith("None") && (audioUrl.startsWith("http://") || audioUrl.startsWith("https://"))) {
                    callback(true, audioUrl, realFmt);
                    return;
                }
            }

            // Step 3: If FLAC failed, fallback to 320k high quality
            if (quality == QualityType::Lossless_FLAC) {
                SongItem s = song;
                s.id = rid;
                resolveAudioUrl(s, QualityType::High_320k, callback);
                return;
            }

            // Step 4: Tertiary fallback to antiserver anti.s
            resolveNativeAudioUrl(song, quality, callback);
        });
    });
}

void KuwoProvider::resolveNativeAudioUrl(const SongItem &song, QualityType quality,
                                         std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    QString rid = song.id;
    if (rid.startsWith("MUSIC_")) rid = rid.mid(6);

    QString fmt = "mp3";
    QString br = "";
    if (quality == QualityType::Lossless_FLAC) {
        fmt = "flac";
    } else if (quality == QualityType::High_320k) {
        fmt = "mp3";
        br = "&br=320kmp3";
    }

    QString urlStr = QString("http://antiserver.kuwo.cn/anti.s?type=convert_url&rid=%1&format=%2&response=url%3")
                         .arg(rid, fmt, br);

    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [this, reply, song, quality, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            if (quality != QualityType::Standard_128k) {
                resolveNativeAudioUrl(song, QualityType::Standard_128k, callback);
            } else {
                callback(false, "", "");
            }
            return;
        }

        QString res = QString::fromUtf8(reply->readAll()).trimmed();
        if (res.startsWith("http://") || res.startsWith("https://")) {
            QString ext = res.endsWith(".flac", Qt::CaseInsensitive) ? "flac" : "mp3";
            callback(true, res, ext);
        } else {
            if (quality != QualityType::Standard_128k) {
                resolveNativeAudioUrl(song, QualityType::Standard_128k, callback);
            } else {
                callback(false, "", "");
            }
        }
    });
}

void KuwoProvider::getLyric(const SongItem &song,
                            std::function<void(bool success, const QString &lrc)> callback) {
    QString urlStr = QString("https://m.kuwo.cn/newh5/singles/songinfoandlrc?musicId=%1").arg(song.id);
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

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

        QJsonObject data = doc.object().value("data").toObject();
        QJsonArray lrclist = data.value("lrclist").toArray();
        if (lrclist.isEmpty()) {
            callback(false, "");
            return;
        }

        QString lrcText;
        for (const auto &val : lrclist) {
            QJsonObject line = val.toObject();
            double timeSec = line.value("time").toString().toDouble();
            if (timeSec == 0.0) timeSec = line.value("time").toDouble();
            QString text = line.value("lineLyric").toString().trimmed();

            int m = static_cast<int>(timeSec) / 60;
            double s = timeSec - (m * 60);
            QString timeStr = QString("[%1:%2]")
                                  .arg(m, 2, 10, QChar('0'))
                                  .arg(s, 5, 'f', 2, QChar('0'));
            lrcText += timeStr + text + "\n";
        }

        callback(true, lrcText);
    });
}

void KuwoProvider::getCoverUrl(const SongItem &song,
                               std::function<void(bool success, const QString &coverUrl)> callback) {
    if (!song.coverUrl.isEmpty()) {
        callback(true, song.coverUrl);
        return;
    }
    // Try to get from songinfoandlrc
    QString urlStr = QString("https://m.kuwo.cn/newh5/singles/songinfoandlrc?musicId=%1").arg(song.id);
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            QString pic = doc.object().value("data").toObject().value("songinfo").toObject().value("pic").toString();
            if (!pic.isEmpty()) {
                callback(true, pic);
                return;
            }
        }
        callback(false, "");
    });
}
