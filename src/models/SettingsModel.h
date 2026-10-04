#ifndef SETTINGSMODEL_H
#define SETTINGSMODEL_H

#include <QString>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include "SongItem.h"

class SettingsModel {
public:
    static SettingsModel& instance() {
        static SettingsModel inst;
        return inst;
    }

    void load() {
        QSettings s("MusicDownloader", "Settings");
        QString defaultMusicDir = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
        if (defaultMusicDir.isEmpty()) {
            defaultMusicDir = QDir::currentPath() + "/Downloads";
        } else {
            defaultMusicDir += "/MusicDownloads";
        }

        m_downloadDir = s.value("downloadDir", defaultMusicDir).toString();
        m_defaultQuality = static_cast<QualityType>(s.value("defaultQuality", static_cast<int>(QualityType::High_320k)).toInt());
        m_downloadLyrics = s.value("downloadLyrics", true).toBool();
        m_downloadCover = s.value("downloadCover", true).toBool();
        m_maxConcurrentDownloads = qBound(1, s.value("maxConcurrentDownloads", 5).toInt(), 5);
        m_fileNameFormat = s.value("fileNameFormat", 0).toInt(); // 0: 歌手 - 歌名, 1: 歌名 - 歌手

        QDir dir(m_downloadDir);
        if (!dir.exists()) {
            dir.mkpath(".");
        }
    }

    void save() {
        QSettings s("MusicDownloader", "Settings");
        s.setValue("downloadDir", m_downloadDir);
        s.setValue("defaultQuality", static_cast<int>(m_defaultQuality));
        s.setValue("downloadLyrics", m_downloadLyrics);
        s.setValue("downloadCover", m_downloadCover);
        s.setValue("maxConcurrentDownloads", m_maxConcurrentDownloads);
        s.setValue("fileNameFormat", m_fileNameFormat);
    }

    QString downloadDir() const { return m_downloadDir; }
    void setDownloadDir(const QString &dir) { m_downloadDir = dir; }

    QualityType defaultQuality() const { return m_defaultQuality; }
    void setDefaultQuality(QualityType q) { m_defaultQuality = q; }

    bool downloadLyrics() const { return m_downloadLyrics; }
    void setDownloadLyrics(bool val) { m_downloadLyrics = val; }

    bool downloadCover() const { return m_downloadCover; }
    void setDownloadCover(bool val) { m_downloadCover = val; }

    int maxConcurrentDownloads() const { return m_maxConcurrentDownloads; }
    void setMaxConcurrentDownloads(int count) { m_maxConcurrentDownloads = qBound(1, count, 5); }

    int fileNameFormat() const { return m_fileNameFormat; }
    void setFileNameFormat(int fmt) { m_fileNameFormat = fmt; }

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
    QualityType m_defaultQuality = QualityType::High_320k;
    bool m_downloadLyrics = true;
    bool m_downloadCover = true;
    int m_maxConcurrentDownloads = 5;
    int m_fileNameFormat = 0;
};

#endif // SETTINGSMODEL_H
