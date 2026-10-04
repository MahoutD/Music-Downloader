#include "AppBridge.h"
#include <QDesktopServices>
#include <QFileDialog>
#include <QFileInfo>
#include <QRandomGenerator>
#include <QDebug>

AppBridge::AppBridge(MusicService *musicService,
                     MusicPlayer *player,
                     DownloadManager *dlManager,
                     SourceManager *sourceManager,
                     QObject *parent)
    : QObject(parent),
      m_service(musicService),
      m_player(player),
      m_dlManager(dlManager),
      m_sourceManager(sourceManager) {

    // Player Signal Connections
    connect(m_player, &MusicPlayer::currentSongChanged, this, [this](const SongItem &song) {
        m_currentSong = song;
        emit currentSongChanged();
    });

    connect(m_player, &MusicPlayer::playbackStateChanged, this, [this](bool playing) {
        m_isPlaying = playing;
        m_isLoading = false;
        emit playbackStateChanged();
        emit loadingChanged();
    });

    connect(m_player, &MusicPlayer::loadingSong, this, [this](const SongItem &song) {
        m_currentSong = song;
        m_isLoading = true;
        emit currentSongChanged();
        emit loadingChanged();
    });

    connect(m_player, &MusicPlayer::positionChanged, this, [this](qint64 pos) {
        m_position = pos;
        emit positionChanged();
    });

    connect(m_player, &MusicPlayer::durationChanged, this, [this](qint64 dur) {
        m_duration = dur;
        emit durationChanged();
    });

    connect(m_player, &MusicPlayer::songFinished, this, &AppBridge::onSongFinished);

    connect(m_player, &MusicPlayer::playbackQualityChanged, this, [this](QualityType q) {
        Q_UNUSED(q);
        emit playbackQualityChanged();
    });

    connect(m_player, &MusicPlayer::errorOccurred, this, [this](const QString &err) {
        m_isLoading = false;
        emit loadingChanged();
        emit showToast(err, true);
    });

    // DownloadManager Signal Connections
    connect(m_dlManager, &DownloadManager::taskAdded, this, &AppBridge::downloadTasksChanged);
    connect(m_dlManager, &DownloadManager::taskStatusChanged, this, &AppBridge::downloadTasksChanged);
    connect(m_dlManager, &DownloadManager::taskFinished, this, &AppBridge::downloadTasksChanged);
    connect(m_dlManager, &DownloadManager::taskUpdated, this, &AppBridge::downloadTasksChanged);
    connect(m_dlManager, &DownloadManager::activeCountChanged, this, [this](int active, int max) {
        Q_UNUSED(max)
        m_activeDownloads = active;
        emit activeDownloadsCountChanged();
    });

    // SourceManager Signal Connections
    connect(m_sourceManager, &SourceManager::sourcesChanged, this, &AppBridge::sourcesChanged);
    connect(m_sourceManager, &SourceManager::message, this, [this](const QString &msg) {
        emit showToast(msg, false);
    });
    connect(m_sourceManager, &SourceManager::errorOccurred, this, [this](const QString &err) {
        emit showToast(err, true);
    });
}

QVariantMap AppBridge::currentSong() const {
    return m_currentSong.toMap();
}

int AppBridge::volume() const {
    return m_player->volume();
}

QVariantList AppBridge::playlist() const {
    QVariantList list;
    for (const auto &song : m_playlist) {
        list.append(song.toMap());
    }
    return list;
}

QVariantList AppBridge::downloadTasks() const {
    QVariantList list;
    auto tasks = m_dlManager->tasks();
    for (const auto &t : tasks) {
        QVariantMap map;
        map["taskId"] = t->taskId;
        map["title"] = t->song.title;
        map["artist"] = t->song.artist;
        map["album"] = t->song.album;
        map["coverUrl"] = t->song.coverUrl.isEmpty() ? "qrc:/icons/app.svg" : t->song.coverUrl;
        map["platformName"] = t->song.platformName();
        map["platformColor"] = t->song.platformColor();
        map["platformIcon"] = t->song.platformIconPath();
        map["qualityName"] = t->qualityName();
        map["statusText"] = t->statusText();
        map["statusCode"] = static_cast<int>(t->status);
        map["progress"] = t->progress;
        map["speedText"] = t->speedText;
        map["sizeText"] = QString("%1 / %2").arg(DownloadTask::formatBytes(t->downloadedBytes), DownloadTask::formatBytes(t->totalBytes));
        map["audioFilePath"] = t->audioFilePath;
        list.append(map);
    }
    return list;
}

// --- Search APIs ---
void AppBridge::search(const QString &keyword, int platform, int page, int pageSize) {
    if (keyword.trimmed().isEmpty()) return;
    PlatformType plat = static_cast<PlatformType>(platform);
    m_service->search(keyword.trimmed(), plat, page, pageSize, [this, page](bool ok, const QList<SongItem> &songs, int total) {
        QVariantList list;
        if (ok) {
            for (const auto &s : songs) {
                list.append(s.toMap());
            }
        }
        emit searchFinished(ok, list, total, page);
    });
}

void AppBridge::getHotSearch(int platform) {
    PlatformType plat = static_cast<PlatformType>(platform);
    m_service->getHotSearch(plat, [this](const QStringList &words) {
        emit hotSearchFinished(words);
    });
}

// --- Charts APIs ---
void AppBridge::loadChartList(int platform) {
    PlatformType plat = static_cast<PlatformType>(platform);
    auto charts = m_service->getChartList(plat);
    QVariantList list;
    for (const auto &c : charts) {
        QVariantMap map;
        map["id"] = c.id;
        map["name"] = c.name;
        map["description"] = c.description;
        list.append(map);
    }
    emit chartListFinished(list);
}

void AppBridge::loadChartSongs(int platform, const QString &chartId, int page, int pageSize) {
    PlatformType plat = static_cast<PlatformType>(platform);
    m_service->getChartSongs(plat, chartId, page, pageSize, [this](bool ok, const QList<SongItem> &songs) {
        QVariantList list;
        if (ok) {
            for (const auto &s : songs) {
                list.append(s.toMap());
            }
        }
        emit chartSongsFinished(ok, list);
    });
}

// --- Player & Playlist Controls ---
void AppBridge::playSong(const QVariantMap &songMap, int quality) {
    SongItem s = SongItem::fromMap(songMap);
    if (s.id.isEmpty() || s.title.isEmpty()) return;

    // Check if in playlist
    int foundIdx = -1;
    for (int i = 0; i < m_playlist.size(); ++i) {
        if (m_playlist[i].id == s.id) {
            foundIdx = i;
            break;
        }
    }

    if (foundIdx >= 0) {
        m_currentIndex = foundIdx;
    } else {
        m_playlist.append(s);
        m_currentIndex = m_playlist.size() - 1;
        emit playlistChanged();
    }
    emit currentIndexChanged();

    QualityType q = (quality >= 0) ? static_cast<QualityType>(quality) : m_player->playbackQuality();
    m_player->playSong(s, q);
    fetchLyrics(songMap);
}

int AppBridge::playbackQuality() const {
    return static_cast<int>(m_player->playbackQuality());
}

void AppBridge::setPlaybackQuality(int quality) {
    if (quality < 0 || quality > 2) return;
    m_player->setPlaybackQuality(static_cast<QualityType>(quality));
    emit playbackQualityChanged();
    emit showToast(QString("已切换播放音质为: %1").arg(playbackQualityName()), false);
}

QString AppBridge::playbackQualityName() const {
    switch (m_player->playbackQuality()) {
        case QualityType::Standard_128k: return "128k 标准品质";
        case QualityType::High_320k: return "320k 高品音质";
        case QualityType::Lossless_FLAC: return "FLAC 无损音质";
        default: return "320k";
    }
}

void AppBridge::addToPlaylist(const QVariantMap &songMap) {
    SongItem s = SongItem::fromMap(songMap);
    if (s.id.isEmpty() || s.title.isEmpty()) return;

    for (const auto &item : m_playlist) {
        if (item.id == s.id) {
            emit showToast(QString("《%1》已在播放列表中").arg(s.title), false);
            return;
        }
    }

    m_playlist.append(s);
    emit playlistChanged();
    emit showToast(QString("已将《%1》添加到播放列表").arg(s.title), false);
}

void AppBridge::removeFromPlaylist(int index) {
    if (index < 0 || index >= m_playlist.size()) return;

    m_playlist.removeAt(index);
    if (index == m_currentIndex) {
        if (m_playlist.isEmpty()) {
            m_currentIndex = -1;
            m_player->stop();
        } else {
            if (m_currentIndex >= m_playlist.size()) {
                m_currentIndex = 0;
            }
            m_player->playSong(m_playlist[m_currentIndex]);
        }
    } else if (index < m_currentIndex) {
        m_currentIndex--;
    }

    emit playlistChanged();
    emit currentIndexChanged();
}

void AppBridge::clearPlaylist() {
    m_playlist.clear();
    m_currentIndex = -1;
    m_player->stop();
    emit playlistChanged();
    emit currentIndexChanged();
    emit showToast("播放列表已清空", false);
}

void AppBridge::playAtIndex(int index) {
    if (index < 0 || index >= m_playlist.size()) return;
    m_currentIndex = index;
    emit currentIndexChanged();
    m_player->playSong(m_playlist[index]);
    fetchLyrics(m_playlist[index].toMap());
}

void AppBridge::previousTrack() {
    if (m_playlist.isEmpty()) return;

    if (m_playMode == 3) { // Random
        if (m_playlist.size() > 1) {
            int nextIdx = m_currentIndex;
            while (nextIdx == m_currentIndex) {
                nextIdx = QRandomGenerator::global()->bounded(m_playlist.size());
            }
            m_currentIndex = nextIdx;
        }
    } else {
        if (m_currentIndex > 0) {
            m_currentIndex--;
        } else {
            m_currentIndex = m_playlist.size() - 1;
        }
    }

    emit currentIndexChanged();
    m_player->playSong(m_playlist[m_currentIndex]);
    fetchLyrics(m_playlist[m_currentIndex].toMap());
}

void AppBridge::playPause() {
    m_player->playPause();
}

void AppBridge::nextTrack() {
    if (m_playlist.isEmpty()) return;

    if (m_playMode == 3) { // Random
        if (m_playlist.size() > 1) {
            int nextIdx = m_currentIndex;
            while (nextIdx == m_currentIndex) {
                nextIdx = QRandomGenerator::global()->bounded(m_playlist.size());
            }
            m_currentIndex = nextIdx;
        }
    } else {
        if (m_currentIndex + 1 < m_playlist.size()) {
            m_currentIndex++;
        } else if (m_playMode == 1) { // Loop all
            m_currentIndex = 0;
        } else { // Sequential
            stop();
            emit showToast("已播放到列表最后一首歌曲", false);
            return;
        }
    }

    emit currentIndexChanged();
    m_player->playSong(m_playlist[m_currentIndex]);
    fetchLyrics(m_playlist[m_currentIndex].toMap());
}

void AppBridge::stop() {
    m_player->stop();
    m_isPlaying = false;
    m_position = 0;
    emit playbackStateChanged();
    emit positionChanged();
}

void AppBridge::seek(qint64 posMs) {
    m_player->seek(posMs);
}

void AppBridge::setVolume(int vol) {
    m_player->setVolume(vol);
    emit volumeChanged();
}

void AppBridge::setPlayMode(int mode) {
    m_playMode = mode % 4;
    emit playModeChanged();
    QStringList modeNames = {"顺序播放", "列表循环", "单曲循环", "随机播放"};
    emit showToast(QString("切换播放模式: %1").arg(modeNames[m_playMode]), false);
}

void AppBridge::fetchLyrics(const QVariantMap &songMap) {
    SongItem s = SongItem::fromMap(songMap);
    m_service->getLyric(s, [this, s](bool ok, const QString &lrc) {
        // Only update currentLyrics if this is still the currently playing song!
        if (m_currentSong.id == s.id) {
            m_currentLyrics = ok ? lrc : "暂无歌词信息";
            emit lyricsChanged();
        }
    });
}

void AppBridge::previewLyrics(const QVariantMap &songMap) {
    SongItem s = SongItem::fromMap(songMap);
    if (s.id.isEmpty() || s.title.isEmpty()) return;

    m_service->getLyric(s, [this, s](bool ok, const QString &lrc) {
        QString lyrics = ok ? lrc : "暂无歌词信息";
        emit previewLyricsReady(s.title, s.artist, lyrics);
    });
}

void AppBridge::onSongFinished() {
    if (m_playlist.isEmpty()) return;

    if (m_playMode == 2) { // Single loop
        seek(0);
        m_player->playSong(m_playlist[m_currentIndex]);
    } else {
        nextTrack();
    }
}

// --- Download APIs ---
void AppBridge::downloadSong(const QVariantMap &songMap, int quality) {
    SongItem s = SongItem::fromMap(songMap);
    if (s.id.isEmpty() || s.title.isEmpty()) return;

    QualityType q = (quality >= 0) ? static_cast<QualityType>(quality)
                                   : SettingsModel::instance().defaultQuality();

    m_dlManager->addTask(s, q);
    emit showToast(QString("已将《%1》加入下载队列").arg(s.title), false);
}

void AppBridge::downloadBatch(const QVariantList &songMaps, int quality) {
    int count = 0;
    QualityType q = (quality >= 0) ? static_cast<QualityType>(quality)
                                   : SettingsModel::instance().defaultQuality();

    for (const auto &val : songMaps) {
        SongItem s = SongItem::fromMap(val.toMap());
        if (!s.id.isEmpty() && !s.title.isEmpty()) {
            m_dlManager->addTask(s, q);
            count++;
        }
    }
    emit showToast(QString("已成功添加 %1 首歌曲到下载队列").arg(count), false);
}

void AppBridge::startAllDownloads() {
    m_dlManager->startAll();
}

void AppBridge::pauseAllDownloads() {
    m_dlManager->pauseAll();
}

void AppBridge::clearCompletedDownloads() {
    m_dlManager->clearCompleted();
    emit downloadTasksChanged();
    emit showToast("已清除所有完成的下载任务", false);
}

void AppBridge::pauseTask(const QString &taskId) {
    m_dlManager->pauseTask(taskId);
}

void AppBridge::resumeTask(const QString &taskId) {
    m_dlManager->resumeTask(taskId);
}

void AppBridge::removeTask(const QString &taskId) {
    m_dlManager->removeTask(taskId);
}

void AppBridge::openDownloadDirectory() {
    QString dir = SettingsModel::instance().downloadDir();
    QDir d(dir);
    if (!d.exists()) d.mkpath(".");
    QDesktopServices::openUrl(QUrl::fromLocalFile(dir));
}

void AppBridge::openAudioFile(const QString &path) {
    if (!path.isEmpty() && QFile::exists(path)) {
        QDesktopServices::openUrl(QUrl::fromLocalFile(path));
    }
}

// --- Source Manager APIs ---
bool AppBridge::exportSources(const QString &filePath) {
    return m_sourceManager->exportSources(filePath);
}

bool AppBridge::importSources(const QString &filePath) {
    return m_sourceManager->importSources(filePath);
}

void AppBridge::resetDefaultSources() {
    m_sourceManager->resetDefaultSources();
}

void AppBridge::updateDefaultSources() {
    m_sourceManager->updateDefaultSources();
}

void AppBridge::toggleSource(const QString &id, bool enabled) {
    m_sourceManager->toggleSource(id, enabled);
}

// --- Settings APIs ---
void AppBridge::saveSettings(const QString &dir, int quality, bool lyric, bool cover, int format) {
    auto &s = SettingsModel::instance();
    s.setDownloadDir(dir);
    s.setDefaultQuality(static_cast<QualityType>(quality));
    s.setDownloadLyrics(lyric);
    s.setDownloadCover(cover);
    s.setFileNameFormat(format);
    s.save();
    emit settingsChanged();
    emit showToast("设置已成功保存！", false);
}

QString AppBridge::chooseDirectory() {
    QString current = downloadDir();
    if (current.isEmpty() || !QDir(current).exists()) {
        current = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    }
    QString dir = QFileDialog::getExistingDirectory(nullptr, "选择音乐下载保存目录", current);
    return dir;
}

QString AppBridge::chooseFileDialog(bool isSave, const QString &filter) {
    if (isSave) {
        return QFileDialog::getSaveFileName(nullptr, "导出音源配置文件", "sources.json", filter);
    } else {
        return QFileDialog::getOpenFileName(nullptr, "导入音源配置文件", "", filter);
    }
}
