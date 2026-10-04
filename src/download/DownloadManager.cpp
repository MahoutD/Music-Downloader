#include "DownloadManager.h"
#include "../models/SettingsModel.h"
#include <QUuid>

DownloadManager::DownloadManager(MusicService *musicService, QObject *parent)
    : QObject(parent), m_musicService(musicService) {}

DownloadManager::~DownloadManager() {
    for (auto worker : m_activeWorkers) {
        worker->cancel();
        delete worker;
    }
    m_activeWorkers.clear();
}

int DownloadManager::maxConcurrent() const {
    return SettingsModel::instance().maxConcurrentDownloads();
}

void DownloadManager::setMaxConcurrent(int max) {
    SettingsModel::instance().setMaxConcurrentDownloads(max);
    SettingsModel::instance().save();
    emit activeCountChanged(m_activeWorkers.size(), maxConcurrent());
    processQueue();
}

std::shared_ptr<DownloadTask> DownloadManager::getTask(const QString &taskId) const {
    for (const auto &t : m_tasks) {
        if (t->taskId == taskId) return t;
    }
    return nullptr;
}

QString DownloadManager::addTask(const SongItem &song, QualityType quality) {
    auto task = std::make_shared<DownloadTask>();
    task->taskId = QUuid::createUuid().toString(QUuid::WithoutBraces);
    task->song = song;
    task->quality = quality;
    task->status = DownloadStatus::Waiting;
    task->createdTime = QDateTime::currentDateTime();

    m_tasks.append(task);
    emit taskAdded(task);

    processQueue();
    return task->taskId;
}

void DownloadManager::addBatch(const QList<SongItem> &songs, QualityType quality) {
    for (const auto &song : songs) {
        auto task = std::make_shared<DownloadTask>();
        task->taskId = QUuid::createUuid().toString(QUuid::WithoutBraces);
        task->song = song;
        task->quality = quality;
        task->status = DownloadStatus::Waiting;
        task->createdTime = QDateTime::currentDateTime();

        m_tasks.append(task);
        emit taskAdded(task);
    }
    processQueue();
}

void DownloadManager::pauseTask(const QString &taskId) {
    if (m_activeWorkers.contains(taskId)) {
        auto worker = m_activeWorkers.take(taskId);
        worker->pause();
        worker->deleteLater();
        emit activeCountChanged(m_activeWorkers.size(), maxConcurrent());
        processQueue();
    } else {
        auto task = getTask(taskId);
        if (task && task->status == DownloadStatus::Waiting) {
            task->status = DownloadStatus::Paused;
            emit taskStatusChanged(taskId, DownloadStatus::Paused);
        }
    }
}

void DownloadManager::resumeTask(const QString &taskId) {
    auto task = getTask(taskId);
    if (task && (task->status == DownloadStatus::Paused || task->status == DownloadStatus::Failed)) {
        task->status = DownloadStatus::Waiting;
        task->errorString.clear();
        emit taskStatusChanged(taskId, DownloadStatus::Waiting);
        processQueue();
    }
}

void DownloadManager::retryTask(const QString &taskId) {
    resumeTask(taskId);
}

void DownloadManager::removeTask(const QString &taskId) {
    if (m_activeWorkers.contains(taskId)) {
        auto worker = m_activeWorkers.take(taskId);
        worker->cancel();
        worker->deleteLater();
        emit activeCountChanged(m_activeWorkers.size(), maxConcurrent());
    }

    for (int i = 0; i < m_tasks.size(); ++i) {
        if (m_tasks[i]->taskId == taskId) {
            m_tasks.removeAt(i);
            break;
        }
    }
    emit taskUpdated(taskId);
    processQueue();
}

void DownloadManager::startAll() {
    for (auto &task : m_tasks) {
        if (task->status == DownloadStatus::Paused || task->status == DownloadStatus::Failed) {
            task->status = DownloadStatus::Waiting;
            task->errorString.clear();
            emit taskStatusChanged(task->taskId, DownloadStatus::Waiting);
        }
    }
    processQueue();
}

void DownloadManager::pauseAll() {
    for (auto worker : m_activeWorkers) {
        worker->pause();
        worker->deleteLater();
    }
    m_activeWorkers.clear();

    for (auto &task : m_tasks) {
        if (task->status == DownloadStatus::Waiting || task->status == DownloadStatus::Downloading || task->status == DownloadStatus::Resolving) {
            task->status = DownloadStatus::Paused;
            emit taskStatusChanged(task->taskId, DownloadStatus::Paused);
        }
    }
    emit activeCountChanged(0, maxConcurrent());
}

void DownloadManager::clearCompleted() {
    for (int i = m_tasks.size() - 1; i >= 0; --i) {
        if (m_tasks[i]->status == DownloadStatus::Completed || m_tasks[i]->status == DownloadStatus::Cancelled) {
            QString id = m_tasks[i]->taskId;
            m_tasks.removeAt(i);
            emit taskUpdated(id);
        }
    }
}

void DownloadManager::processQueue() {
    int maxLimit = maxConcurrent();

    while (m_activeWorkers.size() < maxLimit) {
        std::shared_ptr<DownloadTask> nextTask = nullptr;
        for (auto &t : m_tasks) {
            if (t->status == DownloadStatus::Waiting) {
                nextTask = t;
                break;
            }
        }

        if (!nextTask) break; // No waiting tasks

        auto worker = new DownloadWorker(nextTask, m_musicService, this);
        m_activeWorkers[nextTask->taskId] = worker;

        connect(worker, &DownloadWorker::progress, this, [this](const QString &id, int pct, qint64 recv, qint64 tot, const QString &spd) {
            emit taskProgress(id, pct, recv, tot, spd);
        });

        connect(worker, &DownloadWorker::statusChanged, this, [this](const QString &id, DownloadStatus st) {
            emit taskStatusChanged(id, st);
        });

        connect(worker, &DownloadWorker::finished, this, [this, worker](const QString &id, bool ok, const QString &err) {
            m_activeWorkers.remove(id);
            worker->deleteLater();
            emit taskFinished(id, ok, err);
            emit activeCountChanged(m_activeWorkers.size(), maxConcurrent());
            processQueue();
        });

        worker->start();
        emit activeCountChanged(m_activeWorkers.size(), maxLimit);
    }
}
