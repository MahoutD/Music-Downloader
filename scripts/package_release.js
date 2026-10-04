const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.resolve(__dirname, '..');
const distDir = path.join(rootDir, 'dist');
const packageDirName = 'MusicDownloader-v1.0.0-Windows-x64';
const packageDir = path.join(distDir, packageDirName);
const zipPath = path.join(distDir, `${packageDirName}.zip`);
const buildExe = path.join(rootDir, 'build', 'MusicDownloader.exe');

console.log('=== Step 1: Copying freshly built executable ===');
if (!fs.existsSync(buildExe)) {
    console.error('Error: build/MusicDownloader.exe not found!');
    process.exit(1);
}
fs.copyFileSync(buildExe, path.join(packageDir, 'MusicDownloader.exe'));
console.log('Copied MusicDownloader.exe to release directory.');

console.log('=== Step 2: Cleaning up garbled text files in package ===');
const filesInPackage = fs.readdirSync(packageDir);
for (const file of filesInPackage) {
    if (file.endsWith('.txt') && file !== 'README.txt' && file !== '使用说明.txt') {
        console.log(`Removing unexpected or garbled txt file: ${file}`);
        fs.unlinkSync(path.join(packageDir, file));
    }
}

console.log('=== Step 3: Writing clean UTF-8 with BOM README & 使用说明 ===');
const noticeContent = `\uFEFF===================================================
      音悦下载器 (Music Downloader v1.0.0)
===================================================

【软件简介】
基于 Qt 6 (QML) 与 C++17 构建的现代化音乐聚合搜索与无损下载客户端。
支持 QQ音乐、网易云音乐、酷狗音乐、酷我音乐等全网多平台高品质音乐试听与下载。
搭载拟物化 Hi-Fi 直驱黑胶唱片机、桌面悬浮歌词与本地流媒体智能缓存。

【运行方式】
双击 MusicDownloader.exe 即可直接运行。

【主要特性】
1. 默认下载目录位于程序同级 download 文件夹内，可随时在设置中更改。
2. 设置即改即存，无需手动保存：切换下载音质、优先音质、附加元数据等均立即生效。
3. 软件配置及激活音源实时持久化存储于 config.json，重启自动记忆。
4. 支持本地播放缓存与一键清理。
5. 音源解析支持实时可用探测与测速。

【技术支持】
开源仓库：https://github.com/MahoutD/Music-Downloader
===================================================
`;

fs.writeFileSync(path.join(packageDir, 'README.txt'), noticeContent, 'utf8');
fs.writeFileSync(path.join(packageDir, '使用说明.txt'), noticeContent, 'utf8');
console.log('Wrote README.txt and 使用说明.txt with UTF-8 BOM.');

console.log('=== Step 4: Ensuring initial config.json ===');
const initialConfig = {
    "version": "1.0.0",
    "settings": {
        "downloadDir": "download",
        "cacheDir": "cache",
        "defaultQuality": 0,
        "preferredPlaybackQuality": 1,
        "downloadLyrics": true,
        "downloadCover": true,
        "maxConcurrentDownloads": 5,
        "fileNameFormat": 0,
        "cacheEnabled": true,
        "maxCacheSizeMb": 1024,
        "playMode": 0,
        "volume": 80,
        "themeMode": 3,
        "desktopLyricsEnabled": false
    },
    "sources": {
        "currentSourceId": "all",
        "list": [
            {
                "api": "http://nmobi.kuwo.cn/mobi.s",
                "description": "酷我官方移动/车载直连接口，支持无损FLAC与320k高品质VIP音频",
                "enabled": true,
                "id": "kw_mobile",
                "name": "酷我车载/移动端直连源",
                "platform": 4,
                "priority": 1,
                "type": "builtin"
            },
            {
                "api": "https://u.y.qq.com/cgi-bin/musicu.fcg",
                "description": "QQ音乐官方客户端VKey接口，支持标准/高品质音频并接入全网互补",
                "enabled": true,
                "id": "qq_vkey",
                "name": "QQ音乐官方/VKey解析源",
                "platform": 2,
                "priority": 2,
                "type": "builtin"
            },
            {
                "api": "https://music.163.com/song/media/outer/url",
                "description": "网易云音乐外链/Meting接口，支持全网热门与VIP跨源互补解析",
                "enabled": true,
                "id": "wy_cloud",
                "name": "网易云音乐解析源",
                "platform": 1,
                "priority": 3,
                "type": "builtin"
            },
            {
                "api": "http://m.kugou.com/app/i/getSongInfo.php",
                "description": "酷狗官方PlayInfo接口，支持多音轨切换与VIP跨源互补解析",
                "enabled": true,
                "id": "kg_playinfo",
                "name": "酷狗音乐PlayInfo解析源",
                "platform": 3,
                "priority": 4,
                "type": "builtin"
            }
        ]
    }
};
fs.writeFileSync(path.join(packageDir, 'config.json'), JSON.stringify(initialConfig, null, 4), 'utf8');

// Ensure download & cache dirs exist
fs.mkdirSync(path.join(packageDir, 'download'), { recursive: true });
fs.mkdirSync(path.join(packageDir, 'cache'), { recursive: true });

console.log('=== Step 5: Compressing to Zip Archive ===');
if (fs.existsSync(zipPath)) {
    fs.unlinkSync(zipPath);
}

// Use powershell Compress-Archive
console.log(`Compressing ${packageDir} to ${zipPath}...`);
execSync(`powershell -Command "Compress-Archive -Path '${packageDir}' -DestinationPath '${zipPath}' -Force"`, {
    stdio: 'inherit'
});

const zipStats = fs.statSync(zipPath);
console.log(`Packaging complete! Zip size: ${(zipStats.size / (1024 * 1024)).toFixed(2)} MB`);
