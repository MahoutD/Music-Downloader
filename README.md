# 🎵 音悦下载器 (Music Downloader v2.0)

[![Release](https://img.shields.io/github/v/release/MahoutD/Music-Downloader?color=orange&logo=github)](https://github.com/MahoutD/Music-Downloader/releases)
[![Qt 6.8](https://img.shields.io/badge/Qt-6.8.3-41CD52?logo=qt&logoColor=white)](https://www.qt.io/)
[![C++17](https://img.shields.io/badge/C++-17-00599C?logo=c%2B%2B&logoColor=white)](https://en.cppreference.com/)
[![MSVC 2022](https://img.shields.io/badge/Compiler-MSVC%202022%20x64-0078D7?logo=visualstudio&logoColor=white)](https://visualstudio.microsoft.com/)
[![CMake](https://img.shields.io/badge/Build-CMake%20%7C%20Ninja-064F8C?logo=cmake&logoColor=white)](https://cmake.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> 🤖 **特别声明：全流程 AI 研发项目**  
> 本项目之整体架构、核心多线程并发下载引擎、跨平台多流媒体解析机制、Hi-Fi 拟物黑胶唱片机组件、桌面悬浮歌词系统以及全部 C++ / Qt 6 QML 前后端业务代码，均由 **Google Antigravity AI** 独立全流程自主设计、编码、调试与打磨完成。

---

## 🌟 项目简介

**音悦下载器 (Music Downloader v2.0)** 是一款基于 **C++17** 与 **Qt 6 (QML / Qt Quick + MSVC 2022)** 构建的现代化、高性能、全网多平台音乐聚合搜索、高品质无损试听与多线程并发下载客户端。

融合网易云音乐与 QQ 音乐的设计美学，搭载拟物化 **Hi-Fi 直驱黑胶唱片机**、**毫秒级精准同步滚动歌词**、**独立置顶桌面歌词悬浮窗**、**全局音质切换器** 以及 **可导入/导出与一键在线更新的数据源引擎**。

---

## ✨ 核心特性

### 1. ⚡ 强劲的多线程并发下载调度引擎
- **严格的并发控制**：底层基于线程池与任务队列，将同时下载数严格限制为 $\le 5$ 条工作线程，避免网络堵塞与平台风控。
- **全要素任务监控**：实时呈现下载百分比进度、已下载/总文件大小、即时网速（KB/s、MB/s）与任务生命周期状态（*排队中、解析链接中、下载中、已暂停、下载完成、失败*）。
- **完整元数据写入**：支持在下载音频本体的同时，自动下载伴随的歌词文件（`.lrc`，含毫秒级时间戳）与专辑高清封面图片（`.jpg`）。
- **极简管理与本地交互**：精简高效的右键菜单，支持一键“📁 打开所在目录”与“🗑 删除任务”，双击即可呼起系统原生播放器。

### 2. 💿 拟物化 Hi-Fi 直驱黑胶唱片机与沉浸式大屏
- **全要素黑胶唱机机身 (Direct-Drive Turntable)**：
  - 金属拉丝倒角机身底盘、四角精工固定螺丝、品牌激光镌刻。
  - 频闪电源指示灯（播放时呼吸微光脉冲）与 33 ⅓ RPM 测速标贴。
  - 双层铝合金旋转转盘（Platter）与防静电毛毡唱垫（Slipmat）。
- **高仿真黑胶唱片与扇形双向反光**：
  - 微细同心音轨（Lead-in / Music Grooves / Run-out）。
  - 基于物理光学规律的扇形双翼高光光斑（固定光源反射角度，碟片旋转而光斑恒定，立体感非凡）。
  - 碟片平滑无跳变连续旋转（暂停/继续播放不重置角度）。
- **多轴万向金属唱臂系统 (Gimbal Tonearm)**：
  - 双层金属轴承转轴台、镀铬后置配重锤、唱臂固定托架。
  - S 型流线金属臂杆与倾角唱头壳、金质高精度唱针尖。
  - 智能起落转动动效：播放时唱臂轻盈旋转切入唱片边缘，暂停/停止时唱臂平稳抬起归位至托架。
- **毫秒级同步滚动歌词**：当前播放行精准放大居中发光，支持拖动歌词点击跳转指定时间播放。

### 3. 🌐 四大多流媒体深度聚合与跨源智能解析
- **全平台支持**：
  - 🟢 **QQ音乐 (Tencent)**
  - 🔴 **网易云音乐 (NetEase)**
  - 🔵 **酷狗音乐 (KuGou)**
  - 🟠 **酷我音乐 (Kuwo)**
- **VIP / SQ 无损跨源智能补偿**：当源平台因版权协议或 VIP 限制无法直取高品音频时，系统自动启动交叉互补算法，在各大备用音频源中智能检索与校验，高成功率还原无损 FLAC 与 320k HQ 优质音频流。
- **在线播放源一键热更新**：
  - 支持在【设置】或【搜索】页面点击【🔄 更新播放源】，一键从云端拉取并同步最新默认解析规则。
  - 支持用户自主导入第三方 JSON 规则文件，以及导出本地配置与一键恢复默认。

### 4. 💎 全局多音质无缝切换
- **未沉浸常规播放栏 & 沉浸黑胶大屏双端支持**：
  - 💎 **FLAC 无损品质**
  - ✨ **320k 高品质**
  - 🎵 **128k 标准品质**
- 切换音质时自动记忆并平滑跳转至原播放位置，带来极致顺滑的听歌体验。

### 5. 🪟 独立桌面歌词悬浮窗 (锁定播放独占)
- 支持开启轻量透明桌面悬浮窗，可随意拖动至屏幕任意位置。
- **歌词独占保护机制**：桌面歌词严格绑定当前播放中的曲目，即使在搜索页、榜单页点击预览其他歌曲歌词，桌面歌词也始终稳定展示当前在播歌词。

### 6. 🎨 精致现代的 QML 界面与多主题生态
- **四款专属主题**：
  - ☀️ **简约晨曦 (默认)**：现代浅色系，文字边框高对比度调校，清晰柔和。
  - 🌙 **深邃暗夜**：专业极客深色，夜间护眼。
  - 🟢 **QQ音乐绿**：清新灵动，经典生机。
  - 🔴 **网易云红**：复古质感，热烈沉浸。
- **矢量 Canvas 统一图标系统**：所有播放/暂停、前后切歌、停止、折叠等按键均由矢量代码绘制，任何 DPI 缩放下均丝滑锐利。

---

## 📦 绿色免安装版下载 (Releases)

本软件提供开箱即用的 Windows x64 绿色便携版压缩包，已内置完整的 Qt 6.8.3 运行时库、QML 模块及 MSVC 运行库，无需安装任何额外依赖，解压即玩！

👉 **前往下载最新 Release**：  
[🔗 GitHub Releases - Music Downloader v2.0.0](https://github.com/MahoutD/Music-Downloader/releases)

下载压缩包 `MusicDownloader-v2.0-Windows-x64.zip`，解压后双击 `MusicDownloader.exe` 即可启动。

---

## 🏗️ 代码工程目录

```
Music Downloader/
├── CMakeLists.txt              # CMake 构建配置 (Qt6 Quick / Multimedia / Network / RC)
├── app.rc                      # Windows PE 可执行文件图标资源脚本
├── build.bat                   # 一键 MSVC 2022 编译脚本
├── run.bat                     # 快速启动可执行文件脚本
├── resources/
│   ├── icons/                  # 官方平台 SVG 图标与高精 app.ico 多分辨率图标
│   │   ├── app.ico             # 包含 256/128/64/48/32/16 全规格图标
│   │   ├── app.svg             # 矢量应用图标
│   │   ├── qq.svg / netease.svg / kugou.svg / kuwo.svg
│   ├── qml/                    # 纯 QML 现代化前端
│   │   ├── Main.qml            # 主程序窗口框架与导航
│   │   ├── SearchPage.qml      # 聚合搜索 (多选、一键更新播放源、批量下载)
│   │   ├── ChartsPage.qml      # 平台热门排行榜页面
│   │   ├── DownloadPage.qml    # 多线程下载任务管理器 (精简右键菜单、并发指示)
│   │   ├── PlaylistPage.qml    # 播放列表与当前播放队列
│   │   ├── SettingsPage.qml    # 音源管理 (更新/导入/导出)、下载路径设置
│   │   ├── ImmersionPlayer.qml # Hi-Fi 拟物黑胶唱片机、音质切换与同步滚动歌词
│   │   ├── PlayerBar.qml       # 常驻底部播放控制条 (含音质选择器)
│   │   ├── DesktopLyricsWindow.qml # 独立桌面悬浮歌词
│   │   ├── Theme.qml           # 全局响应式主题系统单例 (默认: 简约晨曦)
│   │   ├── PlayModeIcon.qml    # 矢量播放模式图标
│   │   └── AboutDialog.qml     # 关于软件与许可声明对话框
│   └── resources.qrc           # Qt 资源打包文件
└── src/
    ├── bridge/                 # C++ 核心与 QML 界面双向响应桥接层 (AppBridge)
    ├── download/               # 多线程下载队列调度与 DownloadWorker
    ├── models/                 # 核心数据模型 (SongItem, DownloadTask, Settings)
    ├── player/                 # 基于 QMediaPlayer 的多品质音频播放器
    ├── services/               # 各大平台解析引擎与 SourceManager
    └── main.cpp                # 应用程序入口
```

---

## 🛠️ 本地编译构建指南

### 环境要求
- **操作系统**：Windows 10 / Windows 11 (64-bit)
- **编译工具**：Visual Studio 2022 (MSVC v143, x64)
- **Qt 版本**：Qt 6.8.3 (MSVC 2022 64-bit)
- **构建工具**：CMake 3.16+ 与 Ninja

### 一键构建
在项目根目录下双击运行 `build.bat` 即可全自动调用 MSVC 编译器完成 CMake 配置与 Ninja 编译。

### 命令行手动构建
打开 **x64 Native Tools Command Prompt for VS 2022**：
```cmd
cd /d "d:\WorkSpace\AI_Work\Music Downloader"

cmake -B build -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="D:/Qt/6.8.3/msvc2022_64"
cmake --build build --config Release
```

---

## 📜 开源协议与免责声明

1. 本项目开源协议遵循 [MIT License](LICENSE)。
2. 本工具仅供软件开发学习、Qt 6 QML 技术研究与音视频网络传输协议探讨之用。
3. 音频资源版权均归各大版权方及流媒体平台所有，严禁将本软件用于任何形式的商业用途或侵权传播。请支持正版音乐！
