#ifndef NOMINMAX
#define NOMINMAX
#endif

#include "MusicPlayer.h"
#include "../models/SettingsModel.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QDebug>

MusicPlayer::MusicPlayer(MusicService *musicService, QObject *parent)
    : QObject(parent), m_musicService(musicService), m_cacheNam(new QNetworkAccessManager(this)) {
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(m_audioOutput);
    m_audioOutput->setVolume(0.8f);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
        emit playbackStateChanged(state == QMediaPlayer::PlayingState);
    });

    connect(m_player, &QMediaPlayer::positionChanged, this, &MusicPlayer::positionChanged);
    connect(m_player, &QMediaPlayer::durationChanged, this, &MusicPlayer::durationChanged);

    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        if (status == QMediaPlayer::EndOfMedia) {
            emit songFinished();
        }
    });

    connect(m_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error error, const QString &errorString) {
        Q_UNUSED(error)
        emit errorOccurred(errorString);
    });
}

MusicPlayer::~MusicPlayer() {
    stop();
}

void MusicPlayer::playSong(const SongItem &song, QualityType quality) {
    m_currentSong = song;
    m_playbackQuality = quality;
    emit loadingSong(song);
    emit currentSongChanged(song);
    emit playbackQualityChanged(m_playbackQuality);

    auto tryPlayUrl = [this, song](const QString &url) {
        if (m_currentSong.id != song.id) return;
        m_player->stop();
        m_player->setSource(QUrl(url));
        m_player->play();
    };

    // 1. Check local playback cache
    auto &settings = SettingsModel::instance();
    if (settings.cacheEnabled()) {
        QString cDir = settings.cacheDir();
        QString cacheKey = QString("%1_%2").arg(song.id).arg(static_cast<int>(m_playbackQuality));
        QStringList candidateExtensions = {"flac", "mp3", "m4a"};
        for (const auto &ext : candidateExtensions) {
            QString cFile = QDir(cDir).filePath(cacheKey + "." + ext);
            QFileInfo fi(cFile);
            if (fi.exists() && fi.size() > 50000) {
                // Instantly play local cache file
                m_player->stop();
                m_player->setSource(QUrl::fromLocalFile(cFile));
                m_player->play();
                return;
            }
        }
    }

    // 2. Resolve audio URL online
    m_musicService->resolveAudioUrl(song, m_playbackQuality, [this, song, tryPlayUrl](bool ok, const QString &url, const QString &ext) {
        if (ok && !url.isEmpty()) {
            tryPlayUrl(url);

            // Asynchronously cache audio file to local cacheDir in background
            auto &settings = SettingsModel::instance();
            if (settings.cacheEnabled() && url.startsWith("http")) {
                QString cDir = settings.cacheDir();
                QString cleanExt = ext.isEmpty() ? "mp3" : ext;
                QString targetCacheFile = QDir(cDir).filePath(QString("%1_%2.%3").arg(song.id).arg(static_cast<int>(m_playbackQuality)).arg(cleanExt));
                if (!QFile::exists(targetCacheFile)) {
                    QNetworkRequest req;
                    req.setUrl(QUrl(url));
                    req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");
                    QNetworkReply *reply = m_cacheNam->get(req);
                    connect(reply, &QNetworkReply::finished, this, [reply, targetCacheFile]() {
                        if (reply->error() == QNetworkReply::NoError) {
                            QByteArray data = reply->readAll();
                            if (data.size() > 50000) {
                                QFile f(targetCacheFile);
                                if (f.open(QIODevice::WriteOnly)) {
                                    f.write(data);
                                    f.close();
                                }
                            }
                        }
                        reply->deleteLater();
                    });
                }
            }
            return;
        }

        // Fallback quality
        QualityType fallback = (m_playbackQuality == QualityType::Standard_128k) ? QualityType::High_320k : QualityType::Standard_128k;
        m_musicService->resolveAudioUrl(song, fallback, [this, song, tryPlayUrl](bool ok2, const QString &url2, const QString &ext2) {
            Q_UNUSED(ext2)
            if (ok2 && !url2.isEmpty()) {
                tryPlayUrl(url2);
                return;
            }
            emit errorOccurred("无法获取试听音频链接");
        });
    });
}

void MusicPlayer::setPlaybackQuality(QualityType quality) {
    if (m_playbackQuality == quality) return;
    m_playbackQuality = quality;
    emit playbackQualityChanged(m_playbackQuality);

    if (m_currentSong.id.isEmpty()) return;

    qint64 currentPos = m_player->position();
    bool wasPlaying = (m_player->playbackState() == QMediaPlayer::PlayingState);

    SongItem song = m_currentSong;

    // Check cache first for new quality
    auto &settings = SettingsModel::instance();
    if (settings.cacheEnabled()) {
        QString cDir = settings.cacheDir();
        QString cacheKey = QString("%1_%2").arg(song.id).arg(static_cast<int>(m_playbackQuality));
        QStringList candidateExtensions = {"flac", "mp3", "m4a"};
        for (const auto &ext : candidateExtensions) {
            QString cFile = QDir(cDir).filePath(cacheKey + "." + ext);
            QFileInfo fi(cFile);
            if (fi.exists() && fi.size() > 50000) {
                m_player->setSource(QUrl::fromLocalFile(cFile));
                m_player->setPosition(currentPos);
                if (wasPlaying) {
                    m_player->play();
                }
                return;
            }
        }
    }

    m_musicService->resolveAudioUrl(song, m_playbackQuality, [this, song, currentPos, wasPlaying](bool ok, const QString &url, const QString &ext) {
        Q_UNUSED(ext)
        if (m_currentSong.id != song.id) return;
        if (!ok || url.isEmpty()) {
            emit errorOccurred("切换音质失败: 该音源未提供该音质规格");
            return;
        }

        m_player->setSource(QUrl(url));
        m_player->setPosition(currentPos);
        if (wasPlaying) {
            m_player->play();
        }
    });
}

void MusicPlayer::playPause() {
    if (m_player->playbackState() == QMediaPlayer::PlayingState) {
        m_player->pause();
    } else {
        m_player->play();
    }
}

void MusicPlayer::stop() {
    m_player->stop();
}

void MusicPlayer::seek(qint64 positionMs) {
    m_player->setPosition(positionMs);
}

void MusicPlayer::setVolume(int volumePercent) {
    float vol = qBound(0, volumePercent, 100) / 100.0f;
    m_audioOutput->setVolume(vol);
}

bool MusicPlayer::isPlaying() const {
    return m_player->playbackState() == QMediaPlayer::PlayingState;
}

qint64 MusicPlayer::position() const {
    return m_player->position();
}

qint64 MusicPlayer::duration() const {
    return m_player->duration();
}

int MusicPlayer::volume() const {
    return qRound(m_audioOutput->volume() * 100);
}
