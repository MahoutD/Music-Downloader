# 🎵 音悦下载器 (Music Downloader v2.0)

[![Qt 6.8](https://img.shields.io/badge/Qt-6.8.3-41CD52?logo=qt&logoColor=white)](https://www.qt.io/)
[![C++17](https://img.shields.io/badge/C++-17-00599C?logo=c%2B%2B&logoColor=white)](https://en.cppreference.com/)
[![MSVC 2022](https://img.shields.io/badge/Compiler-MSVC%202022%20x64-0078D7?logo=visualstudio&logoColor=white)](https://visualstudio.microsoft.com/)
[![CMake](https://img.shields.io/badge/Build-CMake%20%7C%20Ninja-064F8C?logo=cmake&logoColor=white)](https://cmake.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> 基于 **C++17** 与 **Qt 6 (QML / Qt Quick + MSVC 2022)** 构建的现代化、高性能、全网多平台音乐聚合搜索与多线程下载客户端。融合网易云音乐与QQ音乐的设计美学，支持**黑胶唱片沉浸式滚动歌词**、**多音轨无损试听**、**可导入外部音源引擎**以及**最高5线程并发下载队列**。

---

## ✨ 核心特性

### 1. ⚡ 强劲的多线程并发下载引擎
- **严谨的并发保护**：底层基于事件驱动和任务调度队列，严格控制并发数 $\le 5$ 条工作线程，避免网络堵塞与反爬限制。
- **全要素任务监控**：实时呈现下载百分比进度、已下载/总文件大小、即时网速（KB/s、MB/s）与任务生命周期状态（*排队中、解析链接中、下载中、已暂停、下载完成、失败*）。
- **完整元数据写入**：支持在下载音频本体的同时，自动下载伴随的歌词文件（`.lrc`，含毫秒级时间戳）与专辑高清封面图片（`.jpg`）。
- **极简管理与本地交互**：右键菜单精简高质，支持一键“📁 打开所在目录”与“🗑 删除任务”，双击即可呼起系统原生播放器。

### 2. 🌐 主流音乐平台深度覆盖与智能跨源解析
- **全平台支持**：
  - 🟢 **QQ音乐 (Tencent)**
  - 🔴 **网易云音乐 (NetEase)**
  - 🔵 **酷狗音乐 (KuGou)**
  - 🟠 **酷我音乐 (Kuwo)**
- **VIP / SQ 无损跨源智能补偿**：当源平台因版权协议或 VIP 限制无法直取高品音频时，系统自动启动交叉互补算法，在各大备用音频源中智能检索与校验，高成功率还原无损 FLAC 与 320k HQ 优质音频流。
- **自定义音源导入与导出**：
  - 支持导入第三方音源脚本/JSON 规则配置。
  - 支持一键导出当前生效音源或恢复默认官方数据源。
  - 提供全局音源快速切换下拉选单，搜索与试听即时生效。

### 3. 🎨 现代化 Qt Quick (QML) 界面交互与沉浸式体验
- **黑胶唱片沉浸式全屏播放页**：
  - 仿实体黑胶唱片拟物化旋转动画与唱臂随播放/暂停自适应摆动。
  - 同步滚动歌词引擎：毫秒级精准追踪当前播放行，高亮发光、平滑居中过渡。
  - 交互式音质切换器：点击顶部音质徽章即可自由在 `💎 FLAC 无损`、`✨ 320k 高品`、`🎵 128k 标准` 间无缝平滑切换，自动维持当前播放进度。
  - 极简精致的折叠收起按钮，与桌面端主流音乐软件设计语言深度统一。
- **矢量 Canvas 统一图标体系**：全软件摒弃低质文本表情符号，上一首、播放/暂停、下一首、停止、收起等控制按钮均采用硬件加速的矢量 Canvas 精确绘制，高 DPI 屏幕下锐利不失真。
- **四大主题色一键切换**：
  - ☀️ **简约晨曦 (默认)**：现代清新浅色系，文字与边框色彩经严格对比度校验。
  - 🌙 **深邃暗夜**：极客深灰，护眼沉浸。
  - 🟢 **QQ音乐绿**：清新灵动，经典生机。
  - 🔴 **网易云红**：热烈浓郁，复古质感。
- **独立桌面歌词悬浮窗**：支持将歌词置顶显示在 Windows 桌面上，随时随地掌握歌词进度。

### 4. 🔍 聚合搜索与榜单直达
- **灵活的搜索模式**：支持全网四大平台并发多源聚合搜索，亦可单选平台针对性过滤。
- **多选批量下载**：支持复选框自由多选、一键全选或反选搜索结果，批量推送到下载队列中。
- **实时热搜与权威榜单**：动态对接各平台官方热搜词排行榜，内置网易云飙升榜/热歌榜、QQ音乐流行榜、酷狗TOP500等榜单，支持单曲试听与榜单全量导入。

---

## 🏗️ 架构设计

```
Music Downloader/
├── CMakeLists.txt              # CMake 构建配置 (Qt6 Quick / Multimedia / Network)
├── build.bat                   # 一键 MSVC 2022 编译与部署脚本
├── run.bat                     # 快速启动可执行文件
├── resources/
│   ├── icons/                  # 官方平台与应用 SVG 矢量图标
│   ├── qml/                    # 纯 QML 现代化前端
│   │   ├── Main.qml            # 主程序窗口框架与导航
│   │   ├── SearchPage.qml      # 音乐聚合搜索页 (多选、热搜、右对齐搜索栏)
│   │   ├── ChartsPage.qml      # 平台热门排行榜页面
│   │   ├── DownloadPage.qml    # 多线程下载任务管理器 (精简右键菜单、并发指示器)
│   │   ├── PlaylistPage.qml    # 播放列表与当前播放队列
│   │   ├── SettingsPage.qml    # 音源管理 (导入/导出)、下载路径与首选项
│   │   ├── ImmersionPlayer.qml # 黑胶唱片沉浸播放页 (矢量图标、音质选择、滚动歌词)
│   │   ├── PlayerBar.qml       # 常驻底部播放控制条
│   │   ├── DesktopLyricsWindow.qml # 桌面歌词悬浮窗
│   │   ├── Theme.qml           # 全局响应式主题系统单例 (默认: 简约晨曦)
│   │   └── AboutDialog.qml     # 关于软件与许可声明对话框
│   └── resources.qrc           # Qt 资源打包文件
└── src/
    ├── bridge/                 # C++ 核心与 QML 界面双向响应桥接层 (AppBridge)
    ├── download/               # 多线程下载队列调度与 DownloadWorker
    ├── models/                 # 核心数据模型 (SongItem, DownloadTask, Settings)
    ├── player/                 # 基于 QMediaPlayer 的多品质音频播放器
    ├── services/               # 各大音乐平台解析引擎 (QQ/NetEase/KuGou/Kuwo)
    └── main.cpp                # 应用程序入口
```

---

## 🛠️ 构建与运行环境

- **操作系统**：Windows 10 / Windows 11 (64-bit)
- **开发工具链**：Visual Studio 2022 (MSVC v143, x64)
- **Qt 框架**：Qt 6.8.3 (MSVC 2022 64-bit)
  - 依赖模块：`Core`, `Gui`, `Widgets`, `Network`, `Multimedia`, `Svg`, `Qml`, `Quick`, `QuickControls2`
- **构建系统**：CMake 3.16+ 与 Ninja

---

## 🚀 编译与运行指南

### 方法一：直接运行预编译版本
如已编译生成，直接双击运行：
```cmd
run.bat
```
或执行：
```cmd
build\MusicDownloader.exe
```

### 方法二：通过批处理脚本一键构建
在项目根目录下双击运行 `build.bat`。

### 方法三：命令行手动构建
打开 **x64 Native Tools Command Prompt for VS 2022**：
```cmd
cd /d "d:\WorkSpace\AI_Work\Music Downloader"

cmake -B build -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="D:/Qt/6.8.3/msvc2022_64" -DCMAKE_MAKE_PROGRAM="D:/Qt/Tools/Ninja/ninja.exe"
cmake --build build --config Release

D:\Qt\6.8.3\msvc2022_64\bin\windeployqt.exe --qmldir resources/qml --no-translations build\MusicDownloader.exe
```

---

## 📜 开源许可与免责声明

1. 本项目开源协议遵循 [MIT License](LICENSE)。
2. 本工具仅供软件开发学习、Qt 6 QML 技术研究与音视频网络传输协议探讨之用。
3. 音频资源版权均归各大版权方及流媒体平台所有，严禁将本软件用于任何形式的商业用途或侵权传播。请支持正版音乐！
