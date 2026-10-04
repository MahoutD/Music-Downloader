#include "SourceManager.h"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QDebug>

SourceManager::SourceManager(QObject *parent) : QObject(parent) {
    loadSources();
}

QList<AudioSourceItem> SourceManager::defaultSources() const {
    return {
        {
            "kw_mobile",
            "酷我车载/移动端直连源",
            "builtin",
            true,
            static_cast<int>(PlatformType::Kuwo),
            "酷我官方移动/车载直连接口，支持无损FLAC与320k高品质VIP音频",
            "http://nmobi.kuwo.cn/mobi.s",
            1
        },
        {
            "qq_vkey",
            "QQ音乐官方/VKey解析源",
            "builtin",
            true,
            static_cast<int>(PlatformType::QQMusic),
            "QQ音乐官方客户端VKey接口，支持标准/高品质音频并接入全网互补",
            "https://u.y.qq.com/cgi-bin/musicu.fcg",
            2
        },
        {
            "wy_cloud",
            "网易云音乐解析源",
            "builtin",
            true,
            static_cast<int>(PlatformType::NetEase),
            "网易云音乐外链/Meting接口，支持全网热门与VIP跨源互补解析",
            "https://music.163.com/song/media/outer/url",
            3
        },
        {
            "kg_playinfo",
            "酷狗音乐PlayInfo解析源",
            "builtin",
            true,
            static_cast<int>(PlatformType::KuGou),
            "酷狗官方PlayInfo接口，支持多音轨切换与VIP跨源互补解析",
            "http://m.kugou.com/app/i/getSongInfo.php",
            4
        }
    };
}

QString SourceManager::configFilePath() const {
    QString dirPath = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir d(dirPath);
    if (!d.exists()) {
        d.mkpath(".");
    }
    return d.filePath("sources.json");
}

void SourceManager::loadSources() {
    QFile file(configFilePath());
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) {
        m_sources = defaultSources();
        saveSources();
        return;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) {
        m_sources = defaultSources();
        saveSources();
        return;
    }

    m_sources.clear();
    QJsonArray arr = doc.array();
    for (const auto &val : arr) {
        if (val.isObject()) {
            m_sources.append(AudioSourceItem::fromJson(val.toObject()));
        }
    }

    if (m_sources.isEmpty()) {
        m_sources = defaultSources();
        saveSources();
    }
}

void SourceManager::saveSources() {
    QFile file(configFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "Failed to save sources configuration to" << configFilePath();
        return;
    }

    QJsonArray arr;
    for (const auto &item : m_sources) {
        arr.append(item.toJson());
    }

    QJsonDocument doc(arr);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
}

QVariantList SourceManager::getSourcesVariant() const {
    QVariantList list;
    for (const auto &item : m_sources) {
        list.append(item.toMap());
    }
    return list;
}

bool SourceManager::isPlatformEnabled(PlatformType platform) const {
    int platInt = static_cast<int>(platform);
    for (const auto &item : m_sources) {
        if (item.platform == platInt && item.enabled) {
            return true;
        }
    }
    return false;
}

bool SourceManager::exportSources(const QString &filePath) {
    QString cleanPath = filePath;
    if (cleanPath.startsWith("file:///")) {
        cleanPath = QUrl(cleanPath).toLocalFile();
    }

    QFile file(cleanPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        emit errorOccurred("无法导出音源配置文件: " + file.errorString());
        return false;
    }

    QJsonArray arr;
    for (const auto &item : m_sources) {
        arr.append(item.toJson());
    }

    QJsonDocument doc(arr);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();

    emit message("音源配置已成功导出至: " + cleanPath);
    return true;
}

bool SourceManager::importSources(const QString &filePath) {
    QString cleanPath = filePath;
    if (cleanPath.startsWith("file:///")) {
        cleanPath = QUrl(cleanPath).toLocalFile();
    }

    QFile file(cleanPath);
    if (!file.open(QIODevice::ReadOnly)) {
        emit errorOccurred("无法打开音源配置文件: " + file.errorString());
        return false;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) {
        emit errorOccurred("导入失败: 配置文件格式不正确，必须为音源列表JSON数组");
        return false;
    }

    QJsonArray arr = doc.array();
    if (arr.isEmpty()) {
        emit errorOccurred("导入失败: 音源列表为空");
        return false;
    }

    QList<AudioSourceItem> importedList;
    for (const auto &val : arr) {
        if (val.isObject()) {
            auto obj = val.toObject();
            if (!obj.value("id").toString().isEmpty() && !obj.value("name").toString().isEmpty()) {
                importedList.append(AudioSourceItem::fromJson(obj));
            }
        }
    }

    if (importedList.isEmpty()) {
        emit errorOccurred("导入失败: 未解析到有效音源");
        return false;
    }

    m_sources = importedList;
    saveSources();
    emit sourcesChanged();
    emit message(QString("成功导入 %1 个音源配置！").arg(m_sources.size()));
    return true;
}

void SourceManager::resetDefaultSources() {
    m_sources = defaultSources();
    saveSources();
    emit sourcesChanged();
    emit message("已恢复为默认官方高可用内置音源！");
}

void SourceManager::toggleSource(const QString &id, bool enabled) {
    for (auto &item : m_sources) {
        if (item.id == id) {
            item.enabled = enabled;
            saveSources();
            emit sourcesChanged();
            return;
        }
    }
}
