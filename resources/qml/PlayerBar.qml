import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    height: 88
    color: Theme.bgPlayer
    border.color: Theme.borderSubtle
    border.width: 1

    signal toggleLyricsRequested()
    signal togglePlaylistRequested()
    signal openImmersionRequested()
    signal toggleDesktopLyricsRequested()

    function formatTime(ms) {
        if (!ms || ms <= 0) return "00:00"
        var totalSec = Math.floor(ms / 1000)
        var min = Math.floor(totalSec / 60)
        var sec = totalSec % 60
        var minStr = min < 10 ? "0" + min : "" + min
        var secStr = sec < 10 ? "0" + sec : "" + sec
        return minStr + ":" + secStr
    }

    // Top subtle highlight line
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.border
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16

        // ================= Left: Current Song Info =================
        Item {
            width: 260
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                width: parent.width

                // Album Cover with vinyl record styling & immersion player trigger
                Rectangle {
                    id: coverWrapper
                    width: 52
                    height: 52
                    radius: 8
                    color: Theme.bgCard
                    clip: true
                    border.color: coverMouse.containsMouse ? Theme.accent : Theme.border
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: backend.currentSong.coverUrl ? backend.currentSong.coverUrl : "qrc:/icons/app.svg"
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // Hover overlay with expansion hint
                    Rectangle {
                        anchors.fill: parent
                        color: "#77000000"
                        visible: coverMouse.containsMouse

                        Text {
                            anchors.centerIn: parent
                            text: "⛶"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                        }
                    }

                    MouseArea {
                        id: coverMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openImmersionRequested()
                    }

                    ToolTip.visible: coverMouse.containsMouse
                    ToolTip.text: "点击打开沉浸式歌词与黑胶唱片界面"
                }

                // Title, Artist, Platform Badge
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    width: parent.width - 64

                    Row {
                        spacing: 6
                        width: parent.width

                        Text {
                            text: backend.currentSong.title ? backend.currentSong.title : "未在播放"
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            width: Math.min(implicitWidth, parent.width - (badgeRec.visible ? badgeRec.width + 8 : 0))
                        }

                        Rectangle {
                            id: badgeRec
                            visible: !!backend.currentSong.platformName
                            height: 16
                            width: badgeText.implicitWidth + 8
                            radius: 3
                            color: backend.currentSong.platformColor ? backend.currentSong.platformColor : Theme.accent
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: backend.currentSong.platformName ? backend.currentSong.platformName : ""
                                color: "#FFFFFF"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: backend.currentSong.artist ? backend.currentSong.artist : "选择歌曲点击播放"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }
        }

        // ================= Center: Player Controls & Progress =================
        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 3
            spacing: 5
            width: parent.width - 260 - 320 - 32

            // Playback Buttons Row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                // Play Mode Toggle
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: modeMouse.containsMouse ? Theme.bgCardHover : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    PlayModeIcon {
                        anchors.centerIn: parent
                        mode: backend.playMode
                        iconColor: modeMouse.containsMouse ? Theme.accent : Theme.textSecondary
                    }

                    MouseArea {
                        id: modeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.setPlayMode((backend.playMode + 1) % 4)
                    }

                    ToolTip.visible: modeMouse.containsMouse
                    ToolTip.text: {
                        switch (backend.playMode) {
                            case 0: return "顺序播放"
                            case 1: return "列表循环"
                            case 2: return "单曲循环"
                            case 3: return "随机播放"
                            default: return "播放模式"
                        }
                    }
                }

                // 1. 上一首 (Previous Track - Vector Canvas)
                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: prevMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                    border.color: prevMouse.containsMouse ? Theme.accent : Theme.border
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Canvas {
                        id: prevCanvas
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = prevMouse.containsMouse ? Theme.accent : Theme.textPrimary;
                            // Left bar
                            ctx.fillRect(1, 2, 2.5, 12);
                            // Triangle
                            ctx.beginPath();
                            ctx.moveTo(15, 2);
                            ctx.lineTo(4.5, 8);
                            ctx.lineTo(15, 14);
                            ctx.closePath();
                            ctx.fill();
                        }

                        Connections {
                            target: Theme
                            function onThemeModeChanged() { prevCanvas.requestPaint() }
                        }
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: prevCanvas.requestPaint()
                        onExited: prevCanvas.requestPaint()
                        onClicked: backend.previousTrack()
                    }

                    ToolTip.visible: prevMouse.containsMouse
                    ToolTip.text: "上一首"
                }

                // 2. 播放 / 暂停 (Play / Pause - Circular Accent Button with Vector Canvas)
                Rectangle {
                    width: 46
                    height: 46
                    radius: 23
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: playMouse.containsMouse ? Theme.accentHover : Theme.accentGradientStart }
                        GradientStop { position: 1.0; color: playMouse.containsMouse ? Theme.accentHover : Theme.accentGradientEnd }
                    }
                    anchors.verticalCenter: parent.verticalCenter

                    Canvas {
                        id: playCanvas
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = "#FFFFFF";

                            if (backend.isPlaying) {
                                // Pause bars
                                ctx.fillRect(4, 3, 4, 14);
                                ctx.fillRect(12, 3, 4, 14);
                            } else {
                                // Play triangle
                                ctx.beginPath();
                                ctx.moveTo(5, 2);
                                ctx.lineTo(17, 10);
                                ctx.lineTo(5, 18);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }

                        Connections {
                            target: backend
                            function onPlaybackStateChanged() { playCanvas.requestPaint() }
                        }
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.playPause()
                    }

                    ToolTip.visible: playMouse.containsMouse
                    ToolTip.text: backend.isPlaying ? "暂停" : "播放"
                }

                // 3. 下一首 (Next Track - Vector Canvas)
                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: nextMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                    border.color: nextMouse.containsMouse ? Theme.accent : Theme.border
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Canvas {
                        id: nextCanvas
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = nextMouse.containsMouse ? Theme.accent : Theme.textPrimary;
                            // Triangle
                            ctx.beginPath();
                            ctx.moveTo(1, 2);
                            ctx.lineTo(11.5, 8);
                            ctx.lineTo(1, 14);
                            ctx.closePath();
                            ctx.fill();
                            // Right bar
                            ctx.fillRect(12.5, 2, 2.5, 12);
                        }

                        Connections {
                            target: Theme
                            function onThemeModeChanged() { nextCanvas.requestPaint() }
                        }
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: nextCanvas.requestPaint()
                        onExited: nextCanvas.requestPaint()
                        onClicked: backend.nextTrack()
                    }

                    ToolTip.visible: nextMouse.containsMouse
                    ToolTip.text: "下一首"
                }

                // 4. 停止 (Stop - Vector Canvas)
                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: stopMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                    border.color: stopMouse.containsMouse ? Theme.accent : Theme.border
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Canvas {
                        id: stopCanvas
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = stopMouse.containsMouse ? "#EF4444" : Theme.textPrimary;
                            // Rounded-like square
                            ctx.fillRect(3, 3, 10, 10);
                        }

                        Connections {
                            target: Theme
                            function onThemeModeChanged() { stopCanvas.requestPaint() }
                        }
                    }

                    MouseArea {
                        id: stopMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: stopCanvas.requestPaint()
                        onExited: stopCanvas.requestPaint()
                        onClicked: backend.stop()
                    }

                    ToolTip.visible: stopMouse.containsMouse
                    ToolTip.text: "停止播放"
                }
            }

            // Progress Bar & Time Labels Row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                spacing: 12

                Text {
                    text: root.formatTime(backend.position)
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    horizontalAlignment: Text.AlignRight
                }

                Slider {
                    id: posSlider
                    width: parent.width - 36 - 36 - 24
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: Math.max(1, backend.duration)
                    value: backend.position

                    background: Rectangle {
                        x: posSlider.leftPadding
                        y: posSlider.topPadding + posSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        width: posSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: Theme.border

                        Rectangle {
                            width: posSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.accent
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: posSlider.leftPadding + posSlider.visualPosition * (posSlider.availableWidth - width)
                        y: posSlider.topPadding + posSlider.availableHeight / 2 - height / 2
                        implicitWidth: 12
                        implicitHeight: 12
                        radius: 6
                        color: posSlider.pressed ? Theme.accentHover : "#FFFFFF"
                        border.color: Theme.accent
                        border.width: 2
                    }

                    onMoved: {
                        backend.seek(posSlider.value)
                    }
                }

                Text {
                    text: root.formatTime(backend.duration)
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                }
            }
        }

        // ================= Right: Volume, Lyrics & Playlist Drawer =================
        Row {
            width: 320
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            layoutDirection: Qt.RightToLeft

            // Playlist Drawer Button with Badge
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: plMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "🎵"
                    font.pixelSize: 13
                }

                // Playlist Count Badge
                Rectangle {
                    visible: backend.playlist.length > 0
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.accent
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -4
                    anchors.rightMargin: -4

                    Text {
                        anchors.centerIn: parent
                        text: backend.playlist.length > 99 ? "99+" : backend.playlist.length
                        color: "#FFFFFF"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                MouseArea {
                    id: plMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePlaylistRequested()
                }

                ToolTip.visible: plMouse.containsMouse
                ToolTip.text: "当前播放列表 (" + backend.playlist.length + "首)"
            }

            // Audio Quality Selector in Bottom Player Bar (Requirement 3)
            Item {
                width: barQualityBtn.width
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: barQualityBtn
                    height: 30
                    width: barQualityRow.implicitWidth + 14
                    radius: 15
                    color: barQualityMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                    border.color: barQualityPopup.visible ? Theme.accent : Theme.border
                    border.width: 1

                    Row {
                        id: barQualityRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: {
                                switch (backend.playbackQuality) {
                                    case 2: return "💎 FLAC"
                                    case 1: return "✨ 320k"
                                    default: return "🎵 128k"
                                }
                            }
                            color: Theme.accent
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            text: "▾"
                            color: Theme.textSecondary
                            font.pixelSize: 9
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: barQualityMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barQualityPopup.visible = !barQualityPopup.visible
                    }

                    ToolTip.visible: barQualityMouse.containsMouse
                    ToolTip.text: "当前播放音质: " + backend.playbackQualityName() + " (点击切换)"
                }

                Popup {
                    id: barQualityPopup
                    y: -height - 6
                    x: barQualityBtn.width - width
                    width: 156
                    padding: 6
                    background: Rectangle {
                        color: Theme.bgCard
                        border.color: Theme.border
                        border.width: 1
                        radius: 8
                    }

                    contentItem: Column {
                        spacing: 3
                        Repeater {
                            model: [
                                { q: 2, label: "💎 FLAC 无损" },
                                { q: 1, label: "✨ 320k 高品" },
                                { q: 0, label: "🎵 128k 标准" }
                            ]
                            delegate: Rectangle {
                                width: parent.width
                                height: 30
                                radius: 4
                                color: (backend.playbackQuality === modelData.q) ? Theme.accent : (barQItemMouse.containsMouse ? Theme.bgCardHover : "transparent")

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: (backend.playbackQuality === modelData.q) ? "#FFFFFF" : Theme.textPrimary
                                    font.pixelSize: 11
                                    font.bold: backend.playbackQuality === modelData.q
                                }

                                MouseArea {
                                    id: barQItemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        backend.setPlaybackQuality(modelData.q)
                                        barQualityPopup.visible = false
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Lyrics Button
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: lrcMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "词"
                    color: lrcMouse.containsMouse ? Theme.accent : Theme.textPrimary
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: lrcMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleLyricsRequested()
                }

                ToolTip.visible: lrcMouse.containsMouse
                ToolTip.text: "查看歌词抽屉"
            }

            // Desktop Lyrics Toggle Button
            Rectangle {
                width: 48
                height: 36
                radius: 8
                color: dtLrcMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.color: Theme.border
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 3
                    Text { text: "🖥️"; font.pixelSize: 11 }
                    Text {
                        text: "词"
                        color: dtLrcMouse.containsMouse ? Theme.accent : Theme.textPrimary
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                MouseArea {
                    id: dtLrcMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleDesktopLyricsRequested()
                }

                ToolTip.visible: dtLrcMouse.containsMouse
                ToolTip.text: "开启/关闭桌面悬浮歌词"
            }

            // Volume Control
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: backend.volume === 0 ? "🔇" : "🔊"
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (backend.volume > 0) {
                                backend.setVolume(0)
                            } else {
                                backend.setVolume(70)
                            }
                        }
                    }
                }

                Slider {
                    id: volSlider
                    width: 76
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 100
                    value: backend.volume

                    background: Rectangle {
                        x: volSlider.leftPadding
                        y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                        implicitWidth: 76
                        implicitHeight: 4
                        width: volSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: Theme.border

                        Rectangle {
                            width: volSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.accent
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                        y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                        implicitWidth: 10
                        implicitHeight: 10
                        radius: 5
                        color: "#FFFFFF"
                        border.color: Theme.accent
                        border.width: 1
                    }

                    onMoved: {
                        backend.setVolume(volSlider.value)
                    }
                }
            }
        }
    }
}
