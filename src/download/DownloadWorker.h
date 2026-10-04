#ifndef DOWNLOADWORKER_H
#define DOWNLOADWORKER_H

#include <QObject>
#include <QFile>
#include <QElapsedTimer>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <memory>
#include "../models/DownloadTask.h"
#include "../services/MusicService.h"

class DownloadWorker : public QObject {
    Q_OBJECT
public:
    explicit DownloadWorker(std::shared_ptr<DownloadTask> task,
                           MusicService *musicService,
                           QObject *parent = nullptr);
    ~DownloadWorker();

    void start();
    void pause();
    void cancel();

    QString taskId() const;
    std::shared_ptr<DownloadTask> task() const { return m_task; }

signals:
    void progress(const QString &taskId, int percentage, qint64 downloaded, qint64 total, const QString &speed);
    void finished(const QString &taskId, bool success, const QString &error);
    void statusChanged(const QString &taskId, DownloadStatus status);

private slots:
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void onReadyRead();
    void onReplyFinished();

private:
    std::shared_ptr<DownloadTask> m_task;
    MusicService *m_musicService;
    QNetworkAccessManager *m_nam;
    QNetworkReply *m_audioReply = nullptr;
    QFile *m_audioFile = nullptr;

    QElapsedTimer m_speedTimer;
    qint64 m_lastBytes = 0;
    qint64 m_lastTime = 0;

    bool m_paused = false;
    bool m_cancelled = false;

    void downloadExtraMetadata(const QString &basePath);
};

#endif // DOWNLOADWORKER_H
