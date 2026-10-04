import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: Theme.bgDark

    signal showLyrics(string title, string artist, string lyrics)

    // Right-Click Context Menu
    Menu {
        id: contextMenu
        property var selectedSong: null
        property int selectedIndex: -1

        background: Rectangle {
            implicitWidth: 168
            color: Theme.bgCard
            border.color: Theme.border
            border.width: 1
            radius: 8
        }

        delegate: MenuItem {
            id: cMenuItem
            implicitHeight: 36
            contentItem: Text {
                text: cMenuItem.text
                color: cMenuItem.highlighted ? Theme.accent : Theme.textPrimary
                font.pixelSize: 12
                font.bold: cMenuItem.highlighted
                verticalAlignment: Text.AlignVCenter
                leftPadding: 12
            }
            background: Rectangle {
                color: cMenuItem.highlighted ? Theme.bgCardHover : "transparent"
                radius: 4
            }
        }

        MenuItem {
            text: "▷ 立即播放"
            onTriggered: {
                if (contextMenu.selectedIndex >= 0) backend.playAtIndex(contextMenu.selectedIndex)
            }
        }
        MenuItem {
            text: "⬇ 下载歌曲"
            onTriggered: {
                if (contextMenu.selectedSong) backend.downloadSong(contextMenu.selectedSong, -1)
            }
        }
        MenuItem {
            text: "📝 查看歌词"
            onTriggered: {
                if (contextMenu.selectedSong) {
                    backend.fetchLyrics(contextMenu.selectedSong)
                    root.showLyrics(contextMenu.selectedSong.title, contextMenu.selectedSong.artist, backend.currentLyrics)
                }
            }
        }
        MenuSeparator {}
        MenuItem {
            text: "✕ 移出播放列表"
            onTriggered: {
                if (contextMenu.selectedIndex >= 0) backend.removeFromPlaylist(contextMenu.selectedIndex)
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // 1. Playlist Header Card
        Rectangle {
            width: parent.width
            height: 70
            radius: 8
            color: Theme.bgCard
            border.color: Theme.border
            border.width: 1

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                Rectangle {
                    width: 44
                    height: 44
                    radius: 8
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accentGradientStart }
                        GradientStop { position: 1.0; color: Theme.accentGradientEnd }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "🎵"
                        font.pixelSize: 22
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Row {
                        spacing: 8
                        Text {
                            text: "当前播放列表"
                            color: Theme.textPrimary
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            height: 20
                            width: countTxt.implicitWidth + 12
                            radius: 10
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: countTxt
                                anchors.centerIn: parent
                                text: backend.playlist.length + " 首歌曲"
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: "支持顺序播放、列表循环、单曲循环、随机播放 | 双击即可播放"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                    }
                }
            }

            // Playlist Actions
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // 全部下载
                Rectangle {
                    height: 34
                    width: 100
                    radius: 6
                    color: "#059669"
                    visible: backend.playlist.length > 0

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "⬇"; color: "#FFFFFF"; font.pixelSize: 10 }
                        Text { text: "全部下载"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.downloadBatch(backend.playlist, -1)
                    }
                }

                // 清空列表
                Rectangle {
                    height: 34
                    width: 90
                    radius: 6
                    color: Theme.bgCardHover
                    border.color: Theme.border
                    border.width: 1
                    visible: backend.playlist.length > 0

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "🗑"; font.pixelSize: 11 }
                        Text { text: "清空列表"; color: "#EF4444"; font.pixelSize: 12; font.bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.clearPlaylist()
                    }
                }
            }
        }

        // 2. Table Header
        Rectangle {
            width: parent.width
            height: 36
            color: Theme.bgHeader
            radius: 6
            visible: backend.playlist.length > 0

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text { text: "序号"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 44; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "歌曲名"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 280; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "歌手"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 140; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "专辑"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 140; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "时长"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 60; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "平台"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 80; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "操作"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // 3. Queue ListView
        ListView {
            id: playlistView
            width: parent.width
            height: parent.height - 140
            clip: true
            model: backend.playlist
            spacing: 4

            delegate: Rectangle {
                id: songRow
                width: playlistView.width
                height: 52
                radius: 6

                property bool isCurrentPlaying: backend.currentIndex === index

                color: isCurrentPlaying ? Theme.bgCardHover : (rowMouse.containsMouse ? Theme.bgCardHover : (index % 2 === 0 ? Theme.bgCardAlt : Theme.bgDark))
                border.color: isCurrentPlaying ? Theme.accent : (rowMouse.containsMouse ? Theme.border : "transparent")
                border.width: 1

                // MouseArea for row events
                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    z: 1
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onDoubleClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            backend.playAtIndex(index)
                        }
                    }
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            contextMenu.selectedSong = modelData
                            contextMenu.selectedIndex = index
                            contextMenu.popup()
                        }
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    z: 2

                    // Index / Playing Icon
                    Rectangle {
                        width: 44
                        height: parent.height
                        color: "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: isCurrentPlaying ? "▶" : ("" + (index + 1))
                            color: isCurrentPlaying ? Theme.accent : Theme.textMuted
                            font.pixelSize: isCurrentPlaying ? 14 : 12
                            font.bold: isCurrentPlaying
                        }
                    }

                    // Song Info
                    Row {
                        width: 280
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 4
                            color: Theme.bgCard
                            clip: true
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.fill: parent
                                source: modelData.coverUrl ? modelData.coverUrl : "qrc:/icons/app.svg"
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            width: parent.width - 44

                            Row {
                                spacing: 4
                                width: parent.width

                                Text {
                                    text: modelData.title
                                    color: isCurrentPlaying ? Theme.accent : Theme.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: Math.min(implicitWidth, parent.width - ((modelData && modelData.isVip) ? 32 : 0))
                                }

                                Rectangle {
                                    visible: !!(modelData && modelData.isVip)
                                    height: 14
                                    width: 26
                                    radius: 2
                                    color: "#EF4444"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "VIP"
                                        color: "#FFFFFF"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    // Artist
                    Text {
                        text: modelData.artist
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: 140
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Album
                    Text {
                        text: modelData.album ? modelData.album : "未知专辑"
                        color: Theme.textMuted
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: 140
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Duration
                    Text {
                        text: modelData.durationFormatted ? modelData.durationFormatted : "03:30"
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        width: 60
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Platform Badge
                    Rectangle {
                        width: 70
                        height: 22
                        radius: 4
                        color: modelData.platformColor ? modelData.platformColor : Theme.accent
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            Image {
                                width: 12
                                height: 12
                                source: modelData.platformIcon ? modelData.platformIcon : "qrc:/icons/app.svg"
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.platformName
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Action Buttons (播放, 下载, 歌词, 移出) - z: 10
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        z: 10

                        // 1. 播放
                        Rectangle {
                            height: 28
                            width: 54
                            radius: 4
                            color: isCurrentPlaying ? "#2563EB" : "#1D4ED8"

                            Text {
                                anchors.centerIn: parent
                                text: isCurrentPlaying ? "播放中" : "▷ 播放"
                                color: "#FFFFFF"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.playAtIndex(index)
                            }
                        }

                        // 2. 下载
                        Rectangle {
                            height: 28
                            width: 52
                            radius: 4
                            color: "#059669"

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Text { text: "⬇"; color: "#FFFFFF"; font.pixelSize: 10 }
                                Text { text: "下载"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.downloadSong(modelData, -1)
                            }
                        }

                        // 3. 歌词
                        Rectangle {
                            height: 28
                            width: 48
                            radius: 4
                            color: Theme.bgCard
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "歌词"
                                color: Theme.textSecondary
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    backend.fetchLyrics(modelData)
                                    root.showLyrics(modelData.title, modelData.artist, backend.currentLyrics)
                                }
                            }
                        }

                        // 4. 移除
                        Rectangle {
                            height: 28
                            width: 48
                            radius: 4
                            color: Theme.bgCardHover
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "移除"
                                color: "#EF4444"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.removeFromPlaylist(index)
                            }
                        }
                    }
                }
            }
        }

        // Empty Playlist State
        Item {
            width: parent.width
            height: parent.height - 140
            visible: backend.playlist.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: "🎵"
                    font.pixelSize: 48
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "当前播放列表为空"
                    color: Theme.textSecondary
                    font.pixelSize: 15
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "在搜索或榜单页面点击「+ 列表」或「全部播放」，歌曲将自动进入播放队列"
                    color: Theme.textMuted
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
