import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1200
    height: 800
    minimumWidth: 1020
    minimumHeight: 680
    visible: true
    title: "音乐下载器 - 全网高品质无损音乐下载"
    color: Theme.bgDark

    Component.onCompleted: {
        Theme.setTheme(backend.themeMode)
    }

    // Connections to backend
    Connections {
        target: backend
        function onShowToast(msg, isError) {
            toast.show(msg, isError)
        }
        function onThemeModeChanged() {
            Theme.setTheme(backend.themeMode)
        }
    }

    // Root Content Item for Rendering & High-Resolution Capture
    Item {
        id: appRoot
        anchors.fill: parent

        // Main App Container
        Item {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
        anchors.bottom: playerBar.top

        // 1. Sidebar Navigation
        Sidebar {
            id: sidebar
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: 220
            currentIndex: pageStack.currentIndex
            onTabSelected: function(idx) {
                pageStack.currentIndex = idx
            }
        }

        // 2. Central Page Stack
        StackLayout {
            id: pageStack
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: sidebar.right
            anchors.right: parent.right
            currentIndex: 0

            // Tab 0: 音乐搜索
            SearchPage {
                id: searchPage
                onShowLyrics: function(title, artist, lyrics) {
                    lyricsDrawer.open(title, artist, lyrics)
                }
            }

            // Tab 1: 热门榜单
            ChartsPage {
                id: chartsPage
                onShowLyrics: function(title, artist, lyrics) {
                    lyricsDrawer.open(title, artist, lyrics)
                }
            }

            // Tab 2: 下载管理
            DownloadPage {
                id: downloadPage
            }

            // Tab 3: 播放列表
            PlaylistPage {
                id: playlistPage
                onShowLyrics: function(title, artist, lyrics) {
                    lyricsDrawer.open(title, artist, lyrics)
                }
            }

            // Tab 4: 设置与音源
            SettingsPage {
                id: settingsPage
                onOpenAboutRequested: {
                    aboutDialog.open()
                }
            }
        }

        // 3. Quick Playlist Side Drawer
        Rectangle {
            id: quickPlaylistDrawer
            width: 380
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: Theme.bgCard
            border.color: Theme.border
            border.width: 1
            z: 800
            visible: opacity > 0
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Column {
                anchors.fill: parent
                spacing: 12

                // Drawer Header
                Rectangle {
                    width: parent.width
                    height: 54
                    color: Theme.bgHeader

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text { text: "🎵"; font.pixelSize: 16 }
                        Text {
                            text: "当前播放列表 (" + backend.playlist.length + ")"
                            color: Theme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text {
                            text: "清空"
                            color: "#EF4444"
                            font.pixelSize: 12
                            visible: backend.playlist.length > 0

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.clearPlaylist()
                            }
                        }

                        Text {
                            text: "✕"
                            color: Theme.textSecondary
                            font.pixelSize: 14
                            font.bold: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: quickPlaylistDrawer.opacity = 0
                            }
                        }
                    }
                }

                // Drawer List
                ListView {
                    width: parent.width
                    height: parent.height - 70
                    clip: true
                    model: backend.playlist
                    spacing: 4

                    delegate: Rectangle {
                        width: quickPlaylistDrawer.width - 16
                        height: 48
                        radius: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: backend.currentIndex === index ? Theme.bgCardHover : (qItemMouse.containsMouse ? Theme.bgCardHover : Theme.bgCardAlt)
                        border.color: backend.currentIndex === index ? Theme.accent : "transparent"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: backend.currentIndex === index ? "▶" : ("" + (index + 1))
                                color: backend.currentIndex === index ? Theme.accent : Theme.textMuted
                                font.pixelSize: 11
                                font.bold: true
                                width: 20
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                width: parent.width - 20 - 70

                                Text {
                                    text: modelData.title
                                    color: backend.currentIndex === index ? Theme.accent : Theme.textPrimary
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.artist
                                    color: Theme.textSecondary
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Remove button
                            Text {
                                text: "✕"
                                color: Theme.textMuted
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.removeFromPlaylist(index)
                                }
                            }
                        }

                        MouseArea {
                            id: qItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onDoubleClicked: backend.playAtIndex(index)
                        }
                    }
                }
            }
        }

        // 4. Lyrics Modal Drawer
        LyricsDrawer {
            id: lyricsDrawer
            width: 420
            height: 520
            anchors.centerIn: parent
            z: 900
        }

        Connections {
            target: backend
            function onPreviewLyricsReady(title, artist, lyrics) {
                lyricsDrawer.open(title, artist, lyrics)
            }
        }
    }

    // 5. Bottom Player Bar
    PlayerBar {
        id: playerBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        onToggleLyricsRequested: {
            if (lyricsDrawer.opacity > 0) {
                lyricsDrawer.close()
            } else {
                lyricsDrawer.open(backend.currentSong.title, backend.currentSong.artist, backend.currentLyrics)
            }
        }
        onTogglePlaylistRequested: {
            quickPlaylistDrawer.opacity = quickPlaylistDrawer.opacity > 0 ? 0 : 1
        }
        onOpenImmersionRequested: {
            immersionPlayer.open()
        }
        onToggleDesktopLyricsRequested: {
            desktopLyricsWindow.visible = !desktopLyricsWindow.visible
        }
    }

    // 6. Fullscreen Immersion Vinyl & Lyrics Player
    ImmersionPlayer {
        id: immersionPlayer
        anchors.fill: parent
    }
    } // end appRoot

    // 7. Modal About Dialog
    AboutDialog {
        id: aboutDialog
        anchors.centerIn: parent
    }

    // 8. Desktop Lyrics Window
    DesktopLyricsWindow {
        id: desktopLyricsWindow
    }

    // 9. Floating Notification Toast
    Toast {
        id: toast
    }

    // 10. Automated Screen Capture Timer (Triggered only when --capture-screenshots flag is passed)
    Timer {
        id: captureTimer
        interval: 2200
        repeat: true
        running: (typeof autoCaptureScreenshots !== "undefined") && autoCaptureScreenshots
        property int step: 0
        onTriggered: {
            step++
            console.log("[Capture Timer] Step " + step)
            if (step === 1) {
                // Step 1: Capture 01_home_search.png (Default Light "简约晨曦" theme)
                pageStack.currentIndex = 0
                Theme.setTheme(3)
                appRoot.grabToImage(function(result) {
                    var ok = result.saveToFile(screenshotDir + "/01_home_search.png")
                    console.log("[Screenshot] 01_home_search.png saved: " + ok)
                })
            } else if (step === 2) {
                // Step 2: Trigger search
                searchPage.triggerSearch("周杰伦")
            } else if (step === 3) {
                // Step 3: Capture search results
                appRoot.grabToImage(function(result) {
                    var ok = result.saveToFile(screenshotDir + "/02_search_results.png")
                    console.log("[Screenshot] 02_search_results.png saved: " + ok)
                })
            } else if (step === 4) {
                // Step 4: Switch to Tab 1 (热门榜单)
                pageStack.currentIndex = 1
            } else if (step === 5) {
                // Step 5: Capture Charts page
                appRoot.grabToImage(function(result) {
                    var ok = result.saveToFile(screenshotDir + "/03_hot_charts.png")
                    console.log("[Screenshot] 03_hot_charts.png saved: " + ok)
                })
            } else if (step === 6) {
                // Step 6: Switch to Tab 4 (设置与音源管理)
                pageStack.currentIndex = 4
            } else if (step === 7) {
                // Step 7: Capture Settings & Sources page
                appRoot.grabToImage(function(result) {
                    var ok = result.saveToFile(screenshotDir + "/04_settings_sources.png")
                    console.log("[Screenshot] 04_settings_sources.png saved: " + ok)
                })
            } else if (step === 8) {
                // Step 8: Play song & Open Immersion Vinyl Player
                pageStack.currentIndex = 0
                backend.playSong({
                    "id": "demo_jay_01",
                    "title": "晴天",
                    "artist": "周杰伦",
                    "album": "叶惠美",
                    "coverUrl": "https://y.gtimg.cn/music/photo_new/T002R300x300M000000Mk5ni19clKG.jpg",
                    "platform": 2
                }, 2)
                immersionPlayer.open()
            } else if (step === 9) {
                // Step 9: Capture Vinyl Immersion Player
                appRoot.grabToImage(function(result) {
                    var ok = result.saveToFile(screenshotDir + "/05_vinyl_immersion_player.png")
                    console.log("[Screenshot] 05_vinyl_immersion_player.png saved: " + ok)
                })
            } else if (step === 10) {
                // Step 10: Switch to Dark Night theme
                immersionPlayer.close()
                Theme.setTheme(0)
                pageStack.currentIndex = 0
            } else if (step === 11) {
                // Step 11: Capture Dark Night theme
                appRoot.grabToImage(function(result) {
                    var ok = result.saveToFile(screenshotDir + "/06_dark_night_theme.png")
                    console.log("[Screenshot] 06_dark_night_theme.png saved: " + ok)
                })
            } else if (step === 12) {
                // Step 12: Switch to NetEase Red theme
                Theme.setTheme(2)
                pageStack.currentIndex = 1
            } else if (step === 13) {
                // Step 13: Capture NetEase Red theme
                appRoot.grabToImage(function(result) {
                    var ok = result.saveToFile(screenshotDir + "/07_netease_red_theme.png")
                    console.log("[Screenshot] 07_netease_red_theme.png saved: " + ok)
                })
            } else if (step === 14) {
                captureTimer.running = false
                console.log("[Screenshot] All 7 screenshots captured successfully!")
                Qt.quit()
            }
        }
    }
}
