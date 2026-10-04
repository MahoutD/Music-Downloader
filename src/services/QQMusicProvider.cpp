#include "QQMusicProvider.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QUrlQuery>
#include <QRegularExpression>

QQMusicProvider::QQMusicProvider(QNetworkAccessManager *nam, QObject *parent)
    : QObject(parent), m_nam(nam) {}

QString QQMusicProvider::cleanHtml(const QString &str) {
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

void QQMusicProvider::search(const QString &keyword, int page, int pageSize,
                             std::function<void(bool success, const QList<SongItem> &songs, int total)> callback) {
    QString urlStr = QString("https://c.y.qq.com/soso/fcgi-bin/search_for_qq_cp?g_tk=5381&uin=0&format=json&inCharset=utf-8&outCharset=utf-8&notice=0&platform=h5&needNewCode=1&w=%1&zhidaqu=1&catZhida=1&t=0&flag=1&ie=utf-8&sem=1&aggr=0&perpage=%2&n=%2&p=%3&remoteplace=txt.mqq.all")
                         .arg(QUrl::toPercentEncoding(keyword), QString::number(pageSize), QString::number(page));

    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setRawHeader("Referer", "https://y.qq.com");

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
        QJsonObject songObj = data.value("song").toObject();
        int total = songObj.value("totalnum").toInt();
        QJsonArray list = songObj.value("list").toArray();

        QList<SongItem> songs;
        for (const auto &val : list) {
            QJsonObject obj = val.toObject();
            SongItem song;
            song.id = obj.value("songmid").toString();
            song.title = cleanHtml(obj.value("songname").toString());

            QJsonArray singers = obj.value("singer").toArray();
            QStringList singerNames;
            for (const auto &s : singers) {
                singerNames.append(cleanHtml(s.toObject().value("name").toString()));
            }
            song.artist = singerNames.join(" / ");
            song.album = cleanHtml(obj.value("albumname").toString());
            song.duration = obj.value("interval").toInt();
            song.platform = PlatformType::QQMusic;

            QString albummid = obj.value("albummid").toString();
            if (!albummid.isEmpty()) {
                song.coverUrl = QString("https://y.gtimg.cn/music/photo_new/T002R300x300M000%1.jpg").arg(albummid);
            }
            song.extra = obj;

            if (!song.id.isEmpty() && !song.title.isEmpty()) {
                songs.append(song);
            }
        }
        callback(true, songs, total > 0 ? total : songs.size());
    });
}

void QQMusicProvider::getHotSearch(std::function<void(const QStringList &hotWords)> callback) {
    QString urlStr = "https://c.y.qq.com/splcloud/fcgi-bin/gethotkey.fcg";
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setRawHeader("Referer", "https://y.qq.com");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback({"周杰伦", "林俊杰", "陈奕迅", "邓紫棋", "薛之谦", "王菲", "海阔天空", "晴天"});
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray hotkeys = doc.object().value("data").toObject().value("hotkey").toArray();
        QStringList words;
        for (const auto &val : hotkeys) {
            QString kw = val.toObject().value("k").toString().trimmed();
            if (!kw.isEmpty() && !words.contains(kw)) {
                words.append(kw);
            }
            if (words.size() >= 15) break;
        }
        if (words.isEmpty()) {
            words = {"周杰伦", "林俊杰", "陈奕迅", "邓紫棋", "薛之谦", "王菲", "海阔天空", "晴天"};
        }
        callback(words);
    });
}

QList<ChartInfo> QQMusicProvider::getChartList() {
    return {
        {"26", "QQ热歌榜", "QQ音乐播放量最高的巅峰流行热歌"},
        {"27", "QQ新歌榜", "每日更新最新发行的热门单曲"},
        {"4", "流行指数榜", "全网播放飙升与流行指数榜"},
        {"62", "网络热歌榜", "网络流行度最高的热门潮流单曲"}
    };
}

void QQMusicProvider::getChartSongs(const QString &chartId, int page, int pageSize,
                                   std::function<void(bool success, const QList<SongItem> &songs)> callback) {
    Q_UNUSED(page)
    QString urlStr = QString("https://c.y.qq.com/v8/fcg-bin/fcg_v8_toplist_cp.fcg?topid=%1&format=json").arg(chartId);
    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setRawHeader("Referer", "https://y.qq.com");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, pageSize, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback(false, {});
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray songlist = doc.object().value("songlist").toArray();

        int limit = qMin(songlist.size(), pageSize);
        QList<SongItem> songs;
        for (int i = 0; i < limit; ++i) {
            QJsonObject data = songlist[i].toObject().value("data").toObject();
            SongItem song;
            song.id = data.value("songmid").toString();
            song.title = cleanHtml(data.value("songname").toString());

            QJsonArray singers = data.value("singer").toArray();
            QStringList singerNames;
            for (const auto &s : singers) {
                singerNames.append(cleanHtml(s.toObject().value("name").toString()));
            }
            song.artist = singerNames.join(" / ");
            song.album = cleanHtml(data.value("albumname").toString());
            song.duration = data.value("interval").toInt();
            song.platform = PlatformType::QQMusic;

            QString albummid = data.value("albummid").toString();
            if (!albummid.isEmpty()) {
                song.coverUrl = QString("https://y.gtimg.cn/music/photo_new/T002R300x300M000%1.jpg").arg(albummid);
            }
            song.extra = data;

            if (!song.id.isEmpty() && !song.title.isEmpty()) {
                songs.append(song);
            }
        }
        callback(true, songs);
    });
}

void QQMusicProvider::resolveAudioUrl(const SongItem &song, QualityType quality,
                                      std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    resolveNativeAudioUrl(song, quality, callback);
}

void QQMusicProvider::resolveNativeAudioUrl(const SongItem &song, QualityType quality,
                                            std::function<void(bool success, const QString &url, const QString &ext)> callback) {
    QString prefix = "M500";
    QString fileExt = "mp3";
    if (quality == QualityType::Lossless_FLAC) {
        prefix = "F000";
        fileExt = "flac";
    } else if (quality == QualityType::High_320k) {
        prefix = "M800";
        fileExt = "mp3";
    }

    QString filename = QString("%1%2.%3").arg(prefix, song.id, fileExt);

    QJsonObject req0Param;
    req0Param["guid"] = "12345678";
    req0Param["songmid"] = QJsonArray{song.id};
    req0Param["filename"] = QJsonArray{filename};
    req0Param["songtype"] = QJsonArray{0};
    req0Param["uin"] = "0";
    req0Param["loginflag"] = 1;
    req0Param["platform"] = "20";

    QJsonObject req0;
    req0["module"] = "vkey.GetVkeyServer";
    req0["method"] = "CgiGetVkey";
    req0["param"] = req0Param;

    QJsonObject comm;
    comm["uin"] = 0;
    comm["format"] = "json";
    comm["ct"] = 24;
    comm["cv"] = 0;

    QJsonObject root;
    root["req_0"] = req0;
    root["comm"] = comm;

    QByteArray dataBytes = QJsonDocument(root).toJson(QJsonDocument::Compact);
    QString urlStr = QString("https://u.y.qq.com/cgi-bin/musicu.fcg?data=%1")
                         .arg(QUrl::toPercentEncoding(QString::fromUtf8(dataBytes)));

    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setRawHeader("Referer", "https://y.qq.com");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [this, reply, song, quality, fileExt, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            if (quality != QualityType::Standard_128k) {
                resolveNativeAudioUrl(song, QualityType::Standard_128k, callback);
            } else {
                callback(false, "", "");
            }
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonObject req0Data = doc.object().value("req_0").toObject().value("data").toObject();
        QJsonArray sip = req0Data.value("sip").toArray();
        QJsonArray midurlinfo = req0Data.value("midurlinfo").toArray();

        if (!midurlinfo.isEmpty()) {
            QJsonObject info = midurlinfo[0].toObject();
            QString purl = info.value("purl").toString();
            if (!purl.isEmpty() && !sip.isEmpty()) {
                QString fullUrl = sip[0].toString() + purl;
                callback(true, fullUrl, fileExt);
                return;
            }
        }

        // Retry with standard if higher quality was requested
        if (quality != QualityType::Standard_128k) {
            resolveNativeAudioUrl(song, QualityType::Standard_128k, callback);
        } else {
            callback(false, "", "");
        }
    });
}

void QQMusicProvider::getLyric(const SongItem &song,
                               std::function<void(bool success, const QString &lrc)> callback) {
    QString urlStr = QString("https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg?songmid=%1&g_tk=5381&format=json&inCharset=utf8&outCharset=utf-8")
                         .arg(song.id);

    QNetworkRequest req{QUrl(urlStr)};
    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setRawHeader("Referer", "https://y.qq.com");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, [reply, callback]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            callback(false, "");
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QString base64 = doc.object().value("lyric").toString();
        if (base64.isEmpty()) {
            callback(false, "");
            return;
        }

        QByteArray decoded = QByteArray::fromBase64(base64.toUtf8());
        callback(true, QString::fromUtf8(decoded));
    });
}

void QQMusicProvider::getCoverUrl(const SongItem &song,
                                  std::function<void(bool success, const QString &coverUrl)> callback) {
    if (!song.coverUrl.isEmpty()) {
        callback(true, song.coverUrl);
    } else {
        callback(false, "");
    }
}
