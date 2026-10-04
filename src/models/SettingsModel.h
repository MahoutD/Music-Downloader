#ifndef SETTINGSMODEL_H
#define SETTINGSMODEL_H

#include <QString>
#include <QCoreApplication>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>
#include "SongItem.h"

class SettingsModel {
public:
    static SettingsModel& instance() {
        static SettingsModel inst;
        return inst;
    }

    static QString configFilePath() {
        QString appDir = QCoreApplication::applicationDirPath();
        QString localConfig = QDir(appDir).filePath("config.json");
        return localConfig;
    }

    void load() {
        QString appDir = QCoreApplication::applicationDirPath();
        QString defaultDownload = QDir(appDir).filePath("download");
        QString defaultCache = QDir(appDir).filePath("cache");

        m_downloadDir = QDir::cleanPath(defaultDownload);
        m_cacheDir = QDir::cleanPath(defaultCache);
        m_defaultQuality = QualityType::Standard_128k;       // 0: 标准 128k
        m_preferredPlaybackQuality = QualityType::High_320k;  // 1: 极高 320k
        m_downloadLyrics = true;
        m_downloadCover = true;
        m_maxConcurrentDownloads = 5;
        m_fileNameFormat = 0; // 0: 歌手 - 歌名, 1: 歌名 - 歌手
        m_cacheEnabled = true;
        m_maxCacheSizeMb = 1024;
        m_playMode = 0;
        m_volume = 80;
        m_themeMode = 3;
        m_desktopLyricsEnabled = false;

        QFile file(configFilePath());
        if (file.exists() && file.open(QIODevice::ReadOnly)) {
            QByteArray data = file.readAll();
            file.close();

            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject()) {
                QJsonObject root = doc.object();
                QJsonObject s = root.value("settings").toObject();
                if (!s.isEmpty()) {
                    if (s.contains("downloadDir")) {
                        QString dir = s.value("downloadDir").toString();
                        if (!dir.trimmed().isEmpty()) {
                            if (QDir::isRelativePath(dir)) {
                                m_downloadDir = QDir::cleanPath(QDir(appDir).filePath(dir));
                            } else {
                                m_downloadDir = QDir::cleanPath(dir);
                            }
                        }
                    }
                    if (s.contains("cacheDir")) {
                        QString cdir = s.value("cacheDir").toString();
                        if (!cdir.trimmed().isEmpty()) {
                            if (QDir::isRelativePath(cdir)) {
                                m_cacheDir = QDir::cleanPath(QDir(appDir).filePath(cdir));
                            } else {
                                m_cacheDir = QDir::cleanPath(cdir);
                            }
                        }
                    }
                    if (s.contains("defaultQuality")) {
                        m_defaultQuality = static_cast<QualityType>(qBound(0, s.value("defaultQuality").toInt(), 2));
                    }
                    if (s.contains("preferredPlaybackQuality")) {
                        m_preferredPlaybackQuality = static_cast<QualityType>(qBound(0, s.value("preferredPlaybackQuality").toInt(), 2));
                    }
                    if (s.contains("downloadLyrics")) {
                        m_downloadLyrics = s.value("downloadLyrics").toBool(true);
                    }
                    if (s.contains("downloadCover")) {
                        m_downloadCover = s.value("downloadCover").toBool(true);
                    }
                    if (s.contains("maxConcurrentDownloads")) {
                        m_maxConcurrentDownloads = qBound(1, s.value("maxConcurrentDownloads").toInt(5), 5);
                    }
                    if (s.contains("fileNameFormat")) {
                        m_fileNameFormat = s.value("fileNameFormat").toInt(0);
                    }
                    if (s.contains("cacheEnabled")) {
                        m_cacheEnabled = s.value("cacheEnabled").toBool(true);
                    }
                    if (s.contains("maxCacheSizeMb")) {
                        m_maxCacheSizeMb = s.value("maxCacheSizeMb").toInt(1024);
                    }
                    if (s.contains("playMode")) {
                        m_playMode = s.value("playMode").toInt(0);
                    }
                    if (s.contains("volume")) {
                        m_volume = s.value("volume").toInt(80);
                    }
                    if (s.contains("themeMode")) {
                        m_themeMode = s.value("themeMode").toInt(3);
                    }
                    if (s.contains("desktopLyricsEnabled")) {
                        m_desktopLyricsEnabled = s.value("desktopLyricsEnabled").toBool(false);
                    }
                }
            }
        }

        // Ensure download and cache directories exist
        QDir().mkpath(m_downloadDir);
        QDir().mkpath(m_cacheDir);
    }

    void save() {
        QJsonObject root;
        QFile file(configFilePath());
        if (file.exists() && file.open(QIODevice::ReadOnly)) {
            QByteArray data = file.readAll();
            file.close();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject()) {
                root = doc.object();
            }
        }

        root["version"] = "1.0.0";

        QJsonObject s = root.value("settings").toObject();
        s["downloadDir"] = m_downloadDir;
        s["cacheDir"] = m_cacheDir;
        s["defaultQuality"] = static_cast<int>(m_defaultQuality);
        s["preferredPlaybackQuality"] = static_cast<int>(m_preferredPlaybackQuality);
        s["downloadLyrics"] = m_downloadLyrics;
        s["downloadCover"] = m_downloadCover;
        s["maxConcurrentDownloads"] = m_maxConcurrentDownloads;
        s["fileNameFormat"] = m_fileNameFormat;
        s["cacheEnabled"] = m_cacheEnabled;
        s["maxCacheSizeMb"] = m_maxCacheSizeMb;
        s["playMode"] = m_playMode;
        s["volume"] = m_volume;
        s["themeMode"] = m_themeMode;
        s["desktopLyricsEnabled"] = m_desktopLyricsEnabled;

        root["settings"] = s;

        if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
            file.flush();
            file.close();
        }
    }

    QString downloadDir() const { return m_downloadDir; }
    void setDownloadDir(const QString &dir) {
        if (QDir::isRelativePath(dir)) {
            m_downloadDir = QDir::cleanPath(QDir(QCoreApplication::applicationDirPath()).filePath(dir));
        } else {
            m_downloadDir = QDir::cleanPath(dir);
        }
        QDir().mkpath(m_downloadDir);
    }

    QualityType defaultQuality() const { return m_defaultQuality; }
    void setDefaultQuality(QualityType q) { m_defaultQuality = q; }

    QualityType preferredPlaybackQuality() const { return m_preferredPlaybackQuality; }
    void setPreferredPlaybackQuality(QualityType q) { m_preferredPlaybackQuality = q; }

    bool downloadLyrics() const { return m_downloadLyrics; }
    void setDownloadLyrics(bool val) { m_downloadLyrics = val; }

    bool downloadCover() const { return m_downloadCover; }
    void setDownloadCover(bool val) { m_downloadCover = val; }

    int maxConcurrentDownloads() const { return m_maxConcurrentDownloads; }
    void setMaxConcurrentDownloads(int count) { m_maxConcurrentDownloads = qBound(1, count, 5); }

    int fileNameFormat() const { return m_fileNameFormat; }
    void setFileNameFormat(int fmt) { m_fileNameFormat = fmt; }

    QString cacheDir() const { return m_cacheDir; }
    bool cacheEnabled() const { return m_cacheEnabled; }
    void setCacheEnabled(bool enabled) { m_cacheEnabled = enabled; }

    int maxCacheSizeMb() const { return m_maxCacheSizeMb; }
    void setMaxCacheSizeMb(int mb) { m_maxCacheSizeMb = mb; }

    int playMode() const { return m_playMode; }
    void setPlayMode(int mode) { m_playMode = mode; }

    int volume() const { return m_volume; }
    void setVolume(int vol) { m_volume = vol; }

    int themeMode() const { return m_themeMode; }
    void setThemeMode(int theme) { m_themeMode = theme; }

    bool desktopLyricsEnabled() const { return m_desktopLyricsEnabled; }
    void setDesktopLyricsEnabled(bool en) { m_desktopLyricsEnabled = en; }

    qint64 cacheSizeBytes() const {
        QDir dir(m_cacheDir);
        if (!dir.exists()) return 0;
        qint64 total = 0;
        const auto fileList = dir.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
        for (const auto &fi : fileList) {
            total += fi.size();
        }
        return total;
    }

    QString formattedCacheSize() const {
        qint64 bytes = cacheSizeBytes();
        if (bytes <= 0) return "0.0 MB";
        double mb = bytes / (1024.0 * 1024.0);
        return QString("%1 MB").arg(QString::number(mb, 'f', 1));
    }

    void clearCache() {
        QDir dir(m_cacheDir);
        if (dir.exists()) {
            const auto fileList = dir.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
            for (const auto &fi : fileList) {
                QFile::remove(fi.absoluteFilePath());
            }
        }
    }

    QString formatFileName(const SongItem &song, const QString &extension) const {
        QString baseName;
        QString artist = sanitizeFileName(song.artist);
        QString title = sanitizeFileName(song.title);
        if (artist.isEmpty()) artist = "未知歌手";
        if (title.isEmpty()) title = "未知歌曲";

        if (m_fileNameFormat == 1) {
            baseName = QString("%1 - %2").arg(title, artist);
        } else {
            baseName = QString("%1 - %2").arg(artist, title);
        }
        return baseName + "." + extension;
    }

    static QString sanitizeFileName(const QString &input) {
        QString s = input;
        s.replace("\\", "_");
        s.replace("/", "_");
        s.replace(":", "_");
        s.replace("*", "_");
        s.replace("?", "_");
        s.replace("\"", "_");
        s.replace("<", "_");
        s.replace(">", "_");
        s.replace("|", "_");
        s.replace("\r", "");
        s.replace("\n", "");
        return s.trimmed();
    }

private:
    SettingsModel() {
        load();
    }

    QString m_downloadDir;
    QString m_cacheDir;
    QualityType m_defaultQuality = QualityType::Standard_128k;
    QualityType m_preferredPlaybackQuality = QualityType::High_320k;
    bool m_downloadLyrics = true;
    bool m_downloadCover = true;
    int m_maxConcurrentDownloads = 5;
    int m_fileNameFormat = 0;
    bool m_cacheEnabled = true;
    int m_maxCacheSizeMb = 1024;
    int m_playMode = 0;
    int m_volume = 80;
    int m_themeMode = 0;
    bool m_desktopLyricsEnabled = false;
};

#endif // SETTINGSMODEL_H
