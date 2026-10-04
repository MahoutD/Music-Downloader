const fs = require('fs');
const path = require('path');
const https = require('https');

const token = process.env.GITHUB_TOKEN || '';
const repoOwner = 'MahoutD';
const repoName = 'Music-Downloader';
const releaseId = 402927197;
const assetPath = path.resolve(__dirname, '..', 'dist', 'MusicDownloader-v1.0.0-Windows-x64.zip');

function request(options, body) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve({ statusCode: res.statusCode, data: data ? JSON.parse(data) : {} });
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });
        req.on('error', reject);
        if (body) {
            req.write(body);
        }
        req.end();
    });
}

async function uploadAssetStream(uploadUrl, filePath) {
    return new Promise((resolve, reject) => {
        const stats = fs.statSync(filePath);
        const urlObj = new URL(uploadUrl);
        const options = {
            hostname: urlObj.hostname,
            path: urlObj.pathname + urlObj.search,
            method: 'POST',
            headers: {
                'Authorization': 'token ' + token,
                'User-Agent': 'NodeJS',
                'Content-Type': 'application/zip',
                'Content-Length': stats.size
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve({ statusCode: res.statusCode, data: JSON.parse(data) });
                } else {
                    reject(new Error(`Upload failed HTTP ${res.statusCode}: ${data}`));
                }
            });
        });

        req.on('error', reject);

        const readStream = fs.createReadStream(filePath);
        readStream.pipe(req);
    });
}

async function main() {
    console.log('1. Fetching release info...');
    const releaseRes = await request({
        hostname: 'api.github.com',
        path: `/repos/${repoOwner}/${repoName}/releases/${releaseId}`,
        method: 'GET',
        headers: {
            'Authorization': 'token ' + token,
            'User-Agent': 'NodeJS',
            'Accept': 'application/vnd.github.v3+json'
        }
    });

    const release = releaseRes.data;
    console.log(`Found release: ${release.name} (${release.tag_name})`);

    for (const asset of release.assets) {
        if (asset.name === 'MusicDownloader-v1.0.0-Windows-x64.zip') {
            console.log(`2. Deleting old asset: ${asset.name} (ID: ${asset.id})...`);
            await request({
                hostname: 'api.github.com',
                path: `/repos/${repoOwner}/${repoName}/releases/assets/${asset.id}`,
                method: 'DELETE',
                headers: {
                    'Authorization': 'token ' + token,
                    'User-Agent': 'NodeJS',
                    'Accept': 'application/vnd.github.v3+json'
                }
            });
            console.log('Deleted old asset.');
        }
    }

    console.log('3. Uploading new asset to GitHub Release...');
    const uploadUrl = `https://uploads.github.com/repos/${repoOwner}/${repoName}/releases/${releaseId}/assets?name=MusicDownloader-v1.0.0-Windows-x64.zip`;
    const result = await uploadAssetStream(uploadUrl, assetPath);
    console.log('Upload successful! Asset ID:', result.data.id, 'Browser URL:', result.data.browser_download_url);

    console.log('4. Updating release notes to reflect settings sync and persistence fix...');
    const updatedBody = `## 🎉 音悦下载器 (Music Downloader) v1.0.0 正式发布

### 🌟 核心特性与重大更新：
1. **即时同步与配置持久化 (New & Fixed)**：
   - 设置界面操作**即改即存即生效**：无论是修改下载保存目录、下载默认音质（标准/极高/无损）、播放优先音质、附加元数据（歌词/封面），还是切换界面主题风格，无需额外保存即可立即实时生效！
   - 彻底修复设置在软件关闭或重启后未生效的问题，所有配置（包括当前激活音源）完整实时持久化至根目录 \`config.json\`。
2. **下载音质默认值与偏好修正**：
   - 严格联动设置中的下载品质设定，默认采用标准音质，切换无损 SQ (FLAC) 或极高 HQ (320k) 后下载歌曲立即按所选音质执行下载。
   - 默认下载保存目录设定为程序所在目录下的 \`download\` 文件夹，支持相对路径及任意自定义路径。
3. **本地播放流媒体智能缓存**：
   - 增加播放缓存开关与占用大小实时统计，支持一键安全清理缓存。
4. **全网多平台聚合与高可用 VIP 音源**：
   - 深度集成酷我、QQ音乐、网易云音乐、酷狗音乐高可用解析源，支持单源/智能多源聚合。
   - 优化音源管理界面，去除非必要开关，提供直观的可用状态与网络测速。
5. **拟物化 Hi-Fi 黑胶唱片机沉浸播放**：
   - 唱臂起落吸附、黑胶唱盘 33⅓ RPM 旋转动画、高斯模糊动态唱片封面底色与自适应双行双语滚动歌词。
6. **桌面悬浮歌词与系统级集成**：
   - 独立置顶透明桌面歌词条，专属绑定当前播放曲目，彻底杜绝歌词错位。

### 📦 下载与使用指南：
- 下载下方 \`MusicDownloader-v1.0.0-Windows-x64.zip\` 压缩包。
- 解压后双击 \`MusicDownloader.exe\` 即可直接运行（绿色免安装）。
- 压缩包内附 UTF-8 BOM 编码的 \`使用说明.txt\` 与 \`README.txt\`。

---
> 💡 *本项目核心业务逻辑、Qt6/QML 界面架构、多平台数据解析及打包发布全流程均由 Google AI (Antigravity) 协同自主编写完成。*
`;

    await request({
        hostname: 'api.github.com',
        path: `/repos/${repoOwner}/${repoName}/releases/${releaseId}`,
        method: 'PATCH',
        headers: {
            'Authorization': 'token ' + token,
            'User-Agent': 'NodeJS',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json'
        }
    }, JSON.stringify({
        body: updatedBody
    }));

    console.log('Release notes updated successfully!');
}

main().catch(err => {
    console.error('Error:', err);
    process.exit(1);
});
