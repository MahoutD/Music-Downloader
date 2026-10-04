cmake_minimum_required(VERSION 3.16)
project(MusicDownloader VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Network Multimedia Svg Qml Quick QuickControls2)

if(MSVC)
    add_compile_options(/utf-8 /W3)
endif()

set(SOURCES
    src/main.cpp
    src/models/SongItem.h
    src/models/SettingsModel.h
    src/models/DownloadTask.h
    src/services/IMusicProvider.h
    src/services/KuwoProvider.h
    src/services/KuwoProvider.cpp
    src/services/KuGouProvider.h
    src/services/KuGouProvider.cpp
    src/services/NetEaseProvider.h
    src/services/NetEaseProvider.cpp
    src/services/QQMusicProvider.h
    src/services/QQMusicProvider.cpp
    src/services/MusicService.h
    src/services/MusicService.cpp
    src/services/SourceManager.h
    src/services/SourceManager.cpp
    src/download/DownloadWorker.h
    src/download/DownloadWorker.cpp
    src/download/DownloadManager.h
    src/download/DownloadManager.cpp
    src/player/MusicPlayer.h
    src/player/MusicPlayer.cpp
    src/bridge/AppBridge.h
    src/bridge/AppBridge.cpp
    resources/resources.qrc
    app.rc
)

add_executable(MusicDownloader WIN32 ${SOURCES})

target_link_libraries(MusicDownloader PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Network
    Qt6::Multimedia
    Qt6::Svg
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)
