#ifndef MUSICPLAYER_H
#define MUSICPLAYER_H

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
#include "../models/SongItem.h"
#include "../services/MusicService.h"

class MusicPlayer : public QObject {
    Q_OBJECT
public:
    explicit MusicPlayer(MusicService *musicService, QObject *parent = nullptr);
    ~MusicPlayer();

    void playSong(const SongItem &song, QualityType quality = QualityType::High_320k);
    void playPause();
    void stop();
    void seek(qint64 positionMs);
    void setVolume(int volumePercent); // 0-100
    void setPlaybackQuality(QualityType quality);

    bool isPlaying() const;
    SongItem currentSong() const { return m_currentSong; }
    QualityType playbackQuality() const { return m_playbackQuality; }
    qint64 position() const;
    qint64 duration() const;
    int volume() const;

signals:
    void currentSongChanged(const SongItem &song);
    void playbackStateChanged(bool isPlaying);
    void playbackQualityChanged(QualityType quality);
    void positionChanged(qint64 posMs);
    void durationChanged(qint64 durMs);
    void errorOccurred(const QString &error);
    void loadingSong(const SongItem &song);
    void songFinished();

private:
    MusicService *m_musicService;
    QMediaPlayer *m_player;
    QAudioOutput *m_audioOutput;
    SongItem m_currentSong;
    QualityType m_playbackQuality = QualityType::High_320k;
};

#endif // MUSICPLAYER_H
