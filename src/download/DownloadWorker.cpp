#include "DownloadWorker.h"
#include "../models/SettingsModel.h"
#include <QDir>
#include <QFileInfo>
#include <QDebug>

DownloadWorker::DownloadWorker(std::shared_ptr<DownloadTask> task,
                               MusicService *musicService,
                               QObject *parent)
    : QObject(parent), m_task(task), m_musicService(musicService), m_nam(musicService->networkAccessManager()) {}

DownloadWorker::~DownloadWorker() {
    if (m_task && m_task->status != DownloadStatus::Completed) {
        cancel();
    }
}

QString DownloadWorker::taskId() const {
    return m_task ? m_task->taskId : QString();
}

void DownloadWorker::start() {
    if (!m_task) return;
    m_paused = false;
    m_cancelled = false;

    m_task->status = DownloadStatus::Resolving;
    emit statusChanged(m_task->taskId, DownloadStatus::Resolving);

    auto startDownloadWithUrl = [this](const QString &url, const QString &ext) {
        // Determine destination paths
        auto &settings = SettingsModel::instance();
        QDir dir(settings.downloadDir());
        if (!dir.exists()) dir.mkpath(".");

        QString fileExt = ext.isEmpty() ? "mp3" : ext;
        QString fileName = settings.formatFileName(m_task->song, fileExt);
        QString fullPath = dir.filePath(fileName);

        m_task->audioFilePath = fullPath;
        m_audioFile = new QFile(fullPath, this);
        if (!m_audioFile->open(QIODevice::WriteOnly)) {
            m_task->status = DownloadStatus::Failed;
            m_task->errorString = "无法创建本地文件: " + m_audioFile->errorString();
            emit statusChanged(m_task->taskId, DownloadStatus::Failed);
            emit finished(m_task->taskId, false, m_task->errorString);
            delete m_audioFile;
            m_audioFile = nullptr;
            return;
        }

        m_task->status = DownloadStatus::Downloading;
        emit statusChanged(m_task->taskId, DownloadStatus::Downloading);

        QNetworkRequest req{QUrl(url)};
        req.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
        req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

        m_speedTimer.start();
        m_lastBytes = 0;
        m_lastTime = 0;

        m_audioReply = m_nam->get(req);
        connect(m_audioReply, &QNetworkReply::readyRead, this, &DownloadWorker::onReadyRead);
        connect(m_audioReply, &QNetworkReply::downloadProgress, this, &DownloadWorker::onDownloadProgress);
        connect(m_audioReply, &QNetworkReply::finished, this, &DownloadWorker::onReplyFinished);
    };

    m_musicService->resolveAudioUrl(m_task->song, m_task->quality, [this, startDownloadWithUrl](bool ok, const QString &url, const QString &ext) {
        if (m_cancelled || m_paused) return;

        if (ok && !url.isEmpty()) {
            startDownloadWithUrl(url, ext);
            return;
        }

        // If FLAC was requested and failed, fall back to high 320k
        if (m_task->quality == QualityType::Lossless_FLAC) {
            m_musicService->resolveAudioUrl(m_task->song, QualityType::High_320k, [this, startDownloadWithUrl](bool ok2, const QString &url2, const QString &ext2) {
                if (m_cancelled || m_paused) return;
                if (ok2 && !url2.isEmpty()) {
                    startDownloadWithUrl(url2, ext2);
                    return;
                }

                m_task->status = DownloadStatus::Failed;
                m_task->errorString = "解析音频链接失败(版权或VIP限制)";
                emit statusChanged(m_task->taskId, DownloadStatus::Failed);
                emit finished(m_task->taskId, false, m_task->errorString);
            });
            return;
        }

        m_task->status = DownloadStatus::Failed;
        m_task->errorString = "解析音频链接失败(版权或VIP限制)";
        emit statusChanged(m_task->taskId, DownloadStatus::Failed);
        emit finished(m_task->taskId, false, m_task->errorString);
    });
}

void DownloadWorker::pause() {
    m_paused = true;
    if (m_audioReply) {
        m_audioReply->abort();
        m_audioReply->deleteLater();
        m_audioReply = nullptr;
    }
    if (m_audioFile) {
        m_audioFile->close();
        delete m_audioFile;
        m_audioFile = nullptr;
    }
    if (m_task) {
        m_task->status = DownloadStatus::Paused;
        m_task->speedText = "0 KB/s";
        emit statusChanged(m_task->taskId, DownloadStatus::Paused);
    }
}

void DownloadWorker::cancel() {
    m_cancelled = true;
    if (m_audioReply) {
        m_audioReply->abort();
        m_audioReply->deleteLater();
        m_audioReply = nullptr;
    }
    if (m_audioFile) {
        m_audioFile->close();
        if (!m_task || m_task->status != DownloadStatus::Completed) {
            m_audioFile->remove(); // delete partially downloaded file
        }
        delete m_audioFile;
        m_audioFile = nullptr;
    }
    if (m_task && m_task->status != DownloadStatus::Completed) {
        m_task->status = DownloadStatus::Cancelled;
        m_task->speedText = "0 KB/s";
        emit statusChanged(m_task->taskId, DownloadStatus::Cancelled);
    }
}

void DownloadWorker::onReadyRead() {
    if (m_audioReply && m_audioFile && m_audioFile->isOpen()) {
        m_audioFile->write(m_audioReply->readAll());
    }
}

void DownloadWorker::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal) {
    if (!m_task || m_paused || m_cancelled) return;

    m_task->downloadedBytes = bytesReceived;
    m_task->totalBytes = bytesTotal;

    if (bytesTotal > 0) {
        m_task->progress = static_cast<int>((bytesReceived * 100) / bytesTotal);
    }

    qint64 elapsed = m_speedTimer.elapsed();
    if (elapsed - m_lastTime >= 500) { // update speed every 500ms
        qint64 bytesDiff = bytesReceived - m_lastBytes;
        double secs = (elapsed - m_lastTime) / 1000.0;
        double speedBps = (secs > 0) ? (bytesDiff / secs) : 0;

        m_task->speedText = DownloadTask::formatBytes(static_cast<qint64>(speedBps)) + "/s";

        m_lastBytes = bytesReceived;
        m_lastTime = elapsed;
    }

    emit progress(m_task->taskId, m_task->progress, bytesReceived, bytesTotal, m_task->speedText);
}

void DownloadWorker::onReplyFinished() {
    if (m_paused || m_cancelled) return;

    if (!m_audioReply) return;

    if (m_audioReply->error() != QNetworkReply::NoError) {
        QString err = m_audioReply->errorString();
        m_audioReply->deleteLater();
        m_audioReply = nullptr;

        if (m_audioFile) {
            m_audioFile->close();
            m_audioFile->remove();
            delete m_audioFile;
            m_audioFile = nullptr;
        }

        m_task->status = DownloadStatus::Failed;
        m_task->errorString = err;
        emit statusChanged(m_task->taskId, DownloadStatus::Failed);
        emit finished(m_task->taskId, false, err);
        return;
    }

    // Write any leftover bytes
    if (m_audioFile && m_audioFile->isOpen()) {
        m_audioFile->write(m_audioReply->readAll());
        m_audioFile->flush();
        m_audioFile->close();
        delete m_audioFile;
        m_audioFile = nullptr;
    }

    m_audioReply->deleteLater();
    m_audioReply = nullptr;

    // Download lyrics & cover if requested
    QFileInfo fi(m_task->audioFilePath);
    QString basePath = fi.path() + "/" + fi.completeBaseName();
    downloadExtraMetadata(basePath);
}

void DownloadWorker::downloadExtraMetadata(const QString &basePath) {
    auto &settings = SettingsModel::instance();
    bool dlLrc = settings.downloadLyrics();
    bool dlCover = settings.downloadCover();

    struct MetaContext {
        int pending = 0;
        bool done = false;
    };
    auto ctx = std::make_shared<MetaContext>();

    if (dlLrc) ctx->pending++;
    if (dlCover) ctx->pending++;

    auto checkDone = [this, ctx]() {
        if (ctx->done) return;
        ctx->pending--;
        if (ctx->pending <= 0) {
            ctx->done = true;
            m_task->status = DownloadStatus::Completed;
            m_task->progress = 100;
            m_task->speedText = "下载完成";
            emit statusChanged(m_task->taskId, DownloadStatus::Completed);
            emit finished(m_task->taskId, true, "");
        }
    };

    if (ctx->pending == 0) {
        m_task->status = DownloadStatus::Completed;
        m_task->progress = 100;
        m_task->speedText = "下载完成";
        emit statusChanged(m_task->taskId, DownloadStatus::Completed);
        emit finished(m_task->taskId, true, "");
        return;
    }

    // 1. Lyrics
    if (dlLrc) {
        m_musicService->getLyric(m_task->song, [this, basePath, checkDone](bool ok, const QString &lrc) {
            if (ok && !lrc.isEmpty()) {
                QString lrcPath = basePath + ".lrc";
                QFile lrcFile(lrcPath);
                if (lrcFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
                    lrcFile.write(lrc.toUtf8());
                    lrcFile.close();
                    if (m_task) m_task->lyricFilePath = lrcPath;
                }
            }
            checkDone();
        });
    }

    // 2. Cover image
    if (dlCover) {
        m_musicService->getCoverUrl(m_task->song, [this, basePath, checkDone](bool ok, const QString &coverUrl) {
            if (ok && !coverUrl.isEmpty()) {
                QNetworkRequest imgReq{QUrl(coverUrl)};
                imgReq.setHeader(QNetworkRequest::UserAgentHeader, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                QNetworkReply *imgReply = m_nam->get(imgReq);
                connect(imgReply, &QNetworkReply::finished, [this, imgReply, basePath, checkDone]() {
                    imgReply->deleteLater();
                    if (imgReply->error() == QNetworkReply::NoError) {
                        QByteArray imgData = imgReply->readAll();
                        if (!imgData.isEmpty()) {
                            QString coverPath = basePath + ".jpg";
                            QFile covFile(coverPath);
                            if (covFile.open(QIODevice::WriteOnly)) {
                                covFile.write(imgData);
                                covFile.close();
                                if (m_task) m_task->coverFilePath = coverPath;
                            }
                        }
                    }
                    checkDone();
                });
            } else {
                checkDone();
            }
        });
    }
}
