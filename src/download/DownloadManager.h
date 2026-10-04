#ifndef DOWNLOADMANAGER_H
#define DOWNLOADMANAGER_H

#include <QObject>
#include <QList>
#include <QMap>
#include <memory>
#include "../models/DownloadTask.h"
#include "../services/MusicService.h"
#include "DownloadWorker.h"

class DownloadManager : public QObject {
    Q_OBJECT
public:
    explicit DownloadManager(MusicService *musicService, QObject *parent = nullptr);
    ~DownloadManager();

    QString addTask(const SongItem &song, QualityType quality);
    void addBatch(const QList<SongItem> &songs, QualityType quality);

    void pauseTask(const QString &taskId);
    void resumeTask(const QString &taskId);
    void retryTask(const QString &taskId);
    void removeTask(const QString &taskId);

    void startAll();
    void pauseAll();
    void clearCompleted();

    QList<std::shared_ptr<DownloadTask>> tasks() const { return m_tasks; }
    std::shared_ptr<DownloadTask> getTask(const QString &taskId) const;

    int activeCount() const { return m_activeWorkers.size(); }
    int maxConcurrent() const;
    void setMaxConcurrent(int max);

signals:
    void taskAdded(std::shared_ptr<DownloadTask> task);
    void taskUpdated(const QString &taskId);
    void taskStatusChanged(const QString &taskId, DownloadStatus status);
    void taskProgress(const QString &taskId, int progress, qint64 downloaded, qint64 total, const QString &speed);
    void taskFinished(const QString &taskId, bool success, const QString &error);
    void activeCountChanged(int activeCount, int maxConcurrent);

private:
    MusicService *m_musicService;
    QList<std::shared_ptr<DownloadTask>> m_tasks;
    QMap<QString, DownloadWorker*> m_activeWorkers;

    void processQueue();
};

#endif // DOWNLOADMANAGER_H
