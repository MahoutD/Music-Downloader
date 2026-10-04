#ifndef DOWNLOADTASK_H
#define DOWNLOADTASK_H

#include <QString>
#include <QDateTime>
#include "SongItem.h"

enum class DownloadStatus {
    Waiting = 0,
    Resolving,
    Downloading,
    Paused,
    Completed,
    Failed,
    Cancelled
};

struct DownloadTask {
    QString taskId;
    SongItem song;
    QualityType quality = QualityType::High_320k;
    DownloadStatus status = DownloadStatus::Waiting;
    int progress = 0;
    qint64 downloadedBytes = 0;
    qint64 totalBytes = 0;
    QString speedText = "0 KB/s";
    QString audioFilePath;
    QString lyricFilePath;
    QString coverFilePath;
    QString errorString;
    QDateTime createdTime;

    QString statusText() const {
        switch (status) {
            case DownloadStatus::Waiting: return "排队中";
            case DownloadStatus::Resolving: return "解析链接中";
            case DownloadStatus::Downloading: return "下载中";
            case DownloadStatus::Paused: return "已暂停";
            case DownloadStatus::Completed: return "下载完成";
            case DownloadStatus::Failed: return "失败: " + errorString;
            case DownloadStatus::Cancelled: return "已取消";
            default: return "未知";
        }
    }

    QString qualityText() const {
        switch (quality) {
            case QualityType::Standard_128k: return "128k 标准";
            case QualityType::High_320k: return "320k 高品";
            case QualityType::Lossless_FLAC: return "FLAC 无损";
            default: return "320k";
        }
    }
    QString qualityName() const { return qualityText(); }

    static QString formatBytes(qint64 bytes) {
        if (bytes <= 0) return "0 B";
        const char* units[] = {"B", "KB", "MB", "GB"};
        double size = bytes;
        int unitIndex = 0;
        while (size >= 1024.0 && unitIndex < 3) {
            size /= 1024.0;
            unitIndex++;
        }
        return QString::number(size, 'f', 2) + " " + units[unitIndex];
    }
};

#endif // DOWNLOADTASK_H
