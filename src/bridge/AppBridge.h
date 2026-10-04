#ifndef APPBRIDGE_H
#define APPBRIDGE_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QList>
#include "../models/SongItem.h"
#include "../models/DownloadTask.h"
#include "../models/SettingsModel.h"
#include "../services/MusicService.h"
#include "../services/SourceManager.h"
#include "../player/MusicPlayer.h"
#include "../download/DownloadManager.h"

class AppBridge : public QObject {
    Q_OBJECT

    // Player Properties
    Q_PROPERTY(QVariantMap currentSong READ currentSong NOTIFY currentSongChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playbackStateChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(int playMode READ playMode WRITE setPlayMode NOTIFY playModeChanged)
    Q_PROPERTY(QVariantList playlist READ playlist NOTIFY playlistChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(QString currentLyrics READ currentLyrics NOTIFY lyricsChanged)
    Q_PROPERTY(int playbackQuality READ playbackQuality WRITE setPlaybackQuality NOTIFY playbackQualityChanged)

    // Download Properties
    Q_PROPERTY(QVariantList downloadTasks READ downloadTasks NOTIFY downloadTasksChanged)
    Q_PROPERTY(int activeDownloadsCount READ activeDownloadsCount NOTIFY activeDownloadsCountChanged)
    Q_PROPERTY(int maxConcurrentDownloads READ maxConcurrentDownloads CONSTANT)

    // Source Manager Properties
    Q_PROPERTY(QVariantList sources READ sources NOTIFY sourcesChanged)
    Q_PROPERTY(QString currentSourceId READ currentSourceId WRITE setCurrentSourceId NOTIFY currentSourceIdChanged)

    // Settings Properties
    Q_PROPERTY(QString downloadDir READ downloadDir NOTIFY settingsChanged)
    Q_PROPERTY(int defaultQuality READ defaultQuality NOTIFY settingsChanged)
    Q_PROPERTY(bool downloadLyric READ downloadLyric NOTIFY settingsChanged)
    Q_PROPERTY(bool downloadCover READ downloadCover NOTIFY settingsChanged)
    Q_PROPERTY(int fileNameFormat READ fileNameFormat NOTIFY settingsChanged)

public:
    explicit AppBridge(MusicService *musicService,
                       MusicPlayer *player,
                       DownloadManager *dlManager,
                       SourceManager *sourceManager,
                       QObject *parent = nullptr);

    // Getters for Properties
    QVariantMap currentSong() const;
    bool isPlaying() const { return m_isPlaying; }
    bool isLoading() const { return m_isLoading; }
    qint64 position() const { return m_position; }
    qint64 duration() const { return m_duration; }
    int volume() const;
    int playMode() const { return m_playMode; }
    QVariantList playlist() const;
    int currentIndex() const { return m_currentIndex; }
    QString currentLyrics() const { return m_currentLyrics; }

    QVariantList downloadTasks() const;
    int activeDownloadsCount() const { return m_activeDownloads; }
    int maxConcurrentDownloads() const { return 5; }

    QVariantList sources() const { return m_sourceManager->getSourcesVariant(); }
    QString currentSourceId() const { return m_sourceManager->currentSourceId(); }
    void setCurrentSourceId(const QString &id) {
        m_sourceManager->setCurrentSourceId(id);
        emit currentSourceIdChanged();
    }

    QString downloadDir() const { return SettingsModel::instance().downloadDir(); }
    int defaultQuality() const { return static_cast<int>(SettingsModel::instance().defaultQuality()); }
    bool downloadLyric() const { return SettingsModel::instance().downloadLyrics(); }
    bool downloadCover() const { return SettingsModel::instance().downloadCover(); }
    int fileNameFormat() const { return SettingsModel::instance().fileNameFormat(); }
    int playbackQuality() const;

    // --- Search APIs ---
    Q_INVOKABLE void search(const QString &keyword, int platform, int page = 1, int pageSize = 20);
    Q_INVOKABLE void getHotSearch(int platform);

    // --- Charts APIs ---
    Q_INVOKABLE void loadChartList(int platform);
    Q_INVOKABLE void loadChartSongs(int platform, const QString &chartId, int page = 1, int pageSize = 30);

    // --- Player & Playlist Controls ---
    Q_INVOKABLE void playSong(const QVariantMap &songMap, int quality = -1);
    Q_INVOKABLE void setPlaybackQuality(int quality);
    Q_INVOKABLE QString playbackQualityName() const;
    Q_INVOKABLE void addToPlaylist(const QVariantMap &songMap);
    Q_INVOKABLE void removeFromPlaylist(int index);
    Q_INVOKABLE void clearPlaylist();
    Q_INVOKABLE void playAtIndex(int index);
    Q_INVOKABLE void previousTrack();
    Q_INVOKABLE void playPause();
    Q_INVOKABLE void nextTrack();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void seek(qint64 posMs);
    Q_INVOKABLE void setVolume(int vol);
    Q_INVOKABLE void setPlayMode(int mode);
    Q_INVOKABLE void fetchLyrics(const QVariantMap &songMap);
    Q_INVOKABLE void previewLyrics(const QVariantMap &songMap);

    // --- Download APIs ---
    Q_INVOKABLE void downloadSong(const QVariantMap &songMap, int quality = -1);
    Q_INVOKABLE void downloadBatch(const QVariantList &songMaps, int quality = -1);
    Q_INVOKABLE void startAllDownloads();
    Q_INVOKABLE void pauseAllDownloads();
    Q_INVOKABLE void clearCompletedDownloads();
    Q_INVOKABLE void pauseTask(const QString &taskId);
    Q_INVOKABLE void resumeTask(const QString &taskId);
    Q_INVOKABLE void removeTask(const QString &taskId);
    Q_INVOKABLE void openDownloadDirectory();
    Q_INVOKABLE void openAudioFile(const QString &path);

    // --- Source Manager APIs ---
    Q_INVOKABLE bool exportSources(const QString &filePath);
    Q_INVOKABLE bool importSources(const QString &filePath);
    Q_INVOKABLE void resetDefaultSources();
    Q_INVOKABLE void updateDefaultSources();
    Q_INVOKABLE void toggleSource(const QString &id, bool enabled);

    // --- Settings APIs ---
    Q_INVOKABLE void saveSettings(const QString &dir, int quality, bool lyric, bool cover, int format);
    Q_INVOKABLE QString chooseDirectory();
    Q_INVOKABLE QString chooseFileDialog(bool isSave, const QString &filter = "JSON files (*.json)");

signals:
    // Search Signals
    void searchFinished(bool success, const QVariantList &songs, int total, int page);
    void hotSearchFinished(const QStringList &hotWords);

    // Chart Signals
    void chartListFinished(const QVariantList &charts);
    void chartSongsFinished(bool success, const QVariantList &songs);

    // Player Signals
    void currentSongChanged();
    void playbackStateChanged();
    void loadingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void playModeChanged();
    void playlistChanged();
    void currentIndexChanged();
    void lyricsChanged();
    void previewLyricsReady(const QString &title, const QString &artist, const QString &lyrics);
    void playbackQualityChanged();

    // Download Signals
    void downloadTasksChanged();
    void activeDownloadsCountChanged();

    // Source Manager Signals
    void sourcesChanged();
    void currentSourceIdChanged();

    // Settings Signals
    void settingsChanged();

    // General Notification
    void showToast(const QString &msg, bool isError = false);

private slots:
    void onSongFinished();

private:
    MusicService *m_service;
    MusicPlayer *m_player;
    DownloadManager *m_dlManager;
    SourceManager *m_sourceManager;

    // Player state
    SongItem m_currentSong;
    bool m_isPlaying = false;
    bool m_isLoading = false;
    qint64 m_position = 0;
    qint64 m_duration = 0;
    int m_playMode = 0; // 0: Sequential, 1: Loop, 2: Single, 3: Random
    QList<SongItem> m_playlist;
    int m_currentIndex = -1;
    QString m_currentLyrics;

    // Download state
    int m_activeDownloads = 0;

    void updateDownloadTasks();
};

#endif // APPBRIDGE_H
