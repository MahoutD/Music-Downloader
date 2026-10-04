import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    visible: opacity > 0
    opacity: 0
    color: Theme.bgDark
    z: 2000

    Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    property var lyricLines: []
    property int activeIndex: -1
    property bool userScrolling: false

    function open() {
        parseLrc(backend.currentLyrics)
        root.opacity = 1
    }

    function close() {
        root.opacity = 0
    }

    function formatTime(ms) {
        if (!ms || ms <= 0) return "00:00"
        var totalSec = Math.floor(ms / 1000)
        var min = Math.floor(totalSec / 60)
        var sec = totalSec % 60
        var minStr = min < 10 ? "0" + min : "" + min
        var secStr = sec < 10 ? "0" + sec : "" + sec
        return minStr + ":" + secStr
    }

    // Parse LRC strings into array of { timeMs, text }
    function parseLrc(lrcText) {
        var lines = []
        if (!lrcText || lrcText.trim().length === 0) {
            root.lyricLines = []
            root.activeIndex = -1
            return
        }

        var rawLines = lrcText.split("\n")
        var regex = /\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\](.*)/

        for (var i = 0; i < rawLines.length; i++) {
            var match = regex.exec(rawLines[i])
            if (match) {
                var min = parseInt(match[1])
                var sec = parseInt(match[2])
                var ms = match[3] ? (match[3].length === 2 ? parseInt(match[3]) * 10 : parseInt(match[3])) : 0
                var totalMs = min * 60000 + sec * 1000 + ms
                var txt = match[4].trim()
                if (txt.length > 0) {
                    lines.push({ timeMs: totalMs, text: txt })
                }
            }
        }

        lines.sort(function(a, b) { return a.timeMs - b.timeMs })
        root.lyricLines = lines
        updateActiveLyric(backend.position)
    }

    function updateActiveLyric(posMs) {
        if (!root.lyricLines || root.lyricLines.length === 0) {
            root.activeIndex = -1
            return
        }

        var idx = -1
        for (var i = 0; i < root.lyricLines.length; i++) {
            if (posMs >= root.lyricLines[i].timeMs) {
                idx = i
            } else {
                break
            }
        }

        if (idx !== root.activeIndex) {
            root.activeIndex = idx
            if (!root.userScrolling && idx >= 0 && lyricsListView.count > idx) {
                lyricsListView.positionViewAtIndex(idx, ListView.Center)
            }
        }
    }

    Connections {
        target: backend
        function onLyricsChanged() {
            root.parseLrc(backend.currentLyrics)
        }
        function onPositionChanged() {
            root.updateActiveLyric(backend.position)
        }
        function onCurrentSongChanged() {
            root.parseLrc(backend.currentLyrics)
        }
    }

    // Background Ambient Glow
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bgPlayer }
            GradientStop { position: 0.5; color: Theme.bgDark }
            GradientStop { position: 1.0; color: Theme.bgPlayer }
        }
    }

    // Top subtle bar
    Item {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 64
        z: 10

        // Collapse Button (Left) - Sleek circular button with vector downward chevron
        Rectangle {
            id: collapseBtn
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 38
            radius: 19
            color: collapseMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
            border.color: collapseMouse.containsMouse ? Theme.accent : Theme.border
            border.width: 1

            Canvas {
                id: collapseChevron
                anchors.centerIn: parent
                width: 16
                height: 16
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = collapseMouse.containsMouse ? Theme.accent : Theme.textPrimary;
                    ctx.lineWidth = 2.2;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(3, 5);
                    ctx.lineTo(8, 10);
                    ctx.lineTo(13, 5);
                    ctx.stroke();
                }

                Connections {
                    target: Theme
                    function onThemeModeChanged() { collapseChevron.requestPaint() }
                }
            }

            MouseArea {
                id: collapseMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: collapseChevron.requestPaint()
                onExited: collapseChevron.requestPaint()
                onClicked: root.close()
            }

            ToolTip.visible: collapseMouse.containsMouse
            ToolTip.text: "收起沉浸式播放页"
        }

        // Song Title and Artist in Header (Center)
        Column {
            anchors.centerIn: parent
            spacing: 3

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Text {
                    text: backend.currentSong.title ? backend.currentSong.title : "未在播放"
                    color: Theme.textPrimary
                    font.pixelSize: 17
                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Rectangle {
                    visible: !!backend.currentSong.platformName
                    height: 18
                    width: platText.implicitWidth + 10
                    radius: 4
                    color: backend.currentSong.platformColor ? backend.currentSong.platformColor : Theme.accent
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: platText
                        anchors.centerIn: parent
                        text: backend.currentSong.platformName ? backend.currentSong.platformName : ""
                        color: "#FFFFFF"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: backend.currentSong.artist ? backend.currentSong.artist : "选择歌曲播放"
                color: Theme.textSecondary
                font.pixelSize: 12
            }
        }

        // Quality Selector (Right) - Interactive with popup
        Item {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: qBtn.width

            Rectangle {
                id: qBtn
                height: 32
                width: qRow.implicitWidth + 20
                radius: 16
                color: qMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.color: qPopup.visible ? Theme.accent : Theme.border
                border.width: 1

                Row {
                    id: qRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        id: qText
                        text: {
                            switch (backend.playbackQuality) {
                                case 2: return "💎 FLAC 无损"
                                case 1: return "✨ 320k 高品"
                                default: return "🎵 128k 标准"
                            }
                        }
                        color: Theme.accent
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        text: "▾"
                        color: Theme.textSecondary
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: qMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: qPopup.visible = !qPopup.visible
                }

                ToolTip.visible: qMouse.containsMouse
                ToolTip.text: "点击切换播放音质"
            }

            Popup {
                id: qPopup
                y: qBtn.height + 4
                x: qBtn.width - width
                width: 170
                padding: 6
                background: Rectangle {
                    color: Theme.bgCard
                    border.color: Theme.border
                    border.width: 1
                    radius: 8
                }

                contentItem: Column {
                    spacing: 4
                    Repeater {
                        model: [
                            { q: 2, label: "💎 FLAC 无损音质" },
                            { q: 1, label: "✨ 320k 高品质" },
                            { q: 0, label: "🎵 128k 标准品质" }
                        ]
                        delegate: Rectangle {
                            width: parent.width
                            height: 32
                            radius: 4
                            color: (backend.playbackQuality === modelData.q) ? Theme.accent : (qItemMouse.containsMouse ? Theme.bgCardHover : "transparent")

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
                                id: qItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    backend.setPlaybackQuality(modelData.q)
                                    qPopup.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Main Content: Vinyl Record (Left) and Synchronized Lyrics (Right)
    Item {
        anchors.top: topBar.bottom
        anchors.bottom: bottomPlayerBar.top
        anchors.left: parent.left
        anchors.right: parent.right

        // ---------------- Left: Vinyl Record & Tonearm ----------------
        Item {
            id: leftVinylArea
            width: parent.width * 0.46
            height: parent.height
            anchors.left: parent.left
            anchors.top: parent.top

            // Phonograph Needle / Tonearm
            Item {
                id: tonearm
                width: 120
                height: 160
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: 65
                anchors.top: parent.top
                anchors.topMargin: 20
                z: 20
                transformOrigin: Item.TopLeft
                rotation: backend.isPlaying ? 0 : -32

                Behavior on rotation {
                    NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
                }

                // Needle pivot base
                Rectangle {
                    x: 0; y: 0
                    width: 24; height: 24; radius: 12
                    color: "#94A3B8"
                    border.color: "#475569"; border.width: 2

                    Rectangle {
                        anchors.centerIn: parent
                        width: 10; height: 10; radius: 5
                        color: "#1E293B"
                    }
                }

                // Needle arm rod
                Rectangle {
                    x: 10; y: 12
                    width: 5; height: 120
                    radius: 2
                    color: "#CBD5E1"
                    rotation: 18
                    transformOrigin: Item.Top
                }

                // Needle head / cartridge
                Rectangle {
                    x: 44; y: 125
                    width: 14; height: 24
                    radius: 3
                    color: "#475569"
                    border.color: Theme.accent; border.width: 1
                }
            }

            // Vinyl Record Disc
            Rectangle {
                id: vinylDisc
                width: Math.min(320, parent.width - 40)
                height: width
                radius: width / 2
                anchors.centerIn: parent
                color: "#111827"
                border.color: "#334155"
                border.width: 4

                // Spinning animation when playing
                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 25000
                    loops: Animation.Infinite
                    running: backend.isPlaying && root.opacity > 0
                }

                // Subtle Vinyl Grooves
                Repeater {
                    model: 5
                    delegate: Rectangle {
                        anchors.centerIn: parent
                        width: vinylDisc.width * (0.88 - index * 0.08)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.color: "#1E293B"
                        border.width: 1
                        opacity: 0.7
                    }
                }

                // Album Art inside vinyl record
                Rectangle {
                    id: albumCoverRec
                    width: vinylDisc.width * 0.62
                    height: width
                    radius: width / 2
                    anchors.centerIn: parent
                    clip: true
                    color: Theme.bgCard
                    border.color: "#475569"
                    border.width: 2

                    Image {
                        anchors.fill: parent
                        source: backend.currentSong.coverUrl ? backend.currentSong.coverUrl : "qrc:/icons/app.svg"
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                // Center Spindle Hole
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "#0F172A"
                    border.color: "#94A3B8"
                    border.width: 3
                    anchors.centerIn: parent
                }
            }
        }

        // ---------------- Right: Synchronized Scrolling Lyrics ----------------
        Item {
            id: rightLyricsArea
            anchors.left: leftVinylArea.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 20

            // If no lyrics
            Item {
                anchors.centerIn: parent
                visible: root.lyricLines.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "🎵"
                        font.pixelSize: 42
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "纯音乐，请欣赏或暂未获取到歌词"
                        color: Theme.textSecondary
                        font.pixelSize: 15
                    }
                }
            }

            // Lyrics ListView
            ListView {
                id: lyricsListView
                anchors.fill: parent
                clip: true
                visible: root.lyricLines.length > 0
                model: root.lyricLines
                spacing: 16
                preferredHighlightBegin: height * 0.4
                preferredHighlightEnd: height * 0.4
                highlightRangeMode: ListView.ApplyRange

                onMovementStarted: root.userScrolling = true
                onMovementEnded: {
                    userScrollTimer.restart()
                }

                Timer {
                    id: userScrollTimer
                    interval: 3500
                    onTriggered: {
                        root.userScrolling = false
                        if (root.activeIndex >= 0 && lyricsListView.count > root.activeIndex) {
                            lyricsListView.positionViewAtIndex(root.activeIndex, ListView.Center)
                        }
                    }
                }

                delegate: Item {
                    id: lyricDelegate
                    width: lyricsListView.width
                    height: lrcLineTxt.implicitHeight + 14

                    property bool isActive: index === root.activeIndex

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: lrcLineMouse.containsMouse ? Theme.bgCardHover : "transparent"
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        width: parent.width - 40

                        // Seek cue on hover
                        Text {
                            text: "▶"
                            color: Theme.accent
                            font.pixelSize: 11
                            visible: lrcLineMouse.containsMouse && !lyricDelegate.isActive
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: lrcLineTxt
                            text: modelData.text
                            color: lyricDelegate.isActive ? Theme.accent : (lrcLineMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                            font.pixelSize: lyricDelegate.isActive ? 20 : 15
                            font.bold: lyricDelegate.isActive
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            width: parent.width - (lrcLineMouse.containsMouse ? 24 : 0)
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on font.pixelSize {
                                NumberAnimation { duration: 180 }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 180 }
                            }
                        }
                    }

                    MouseArea {
                        id: lrcLineMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            backend.seek(modelData.timeMs)
                        }
                    }
                }
            }
        }
    }

    // ---------------- Bottom Integrated Player Controls ----------------
    Rectangle {
        id: bottomPlayerBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 100
        color: Theme.bgPlayer
        border.color: Theme.borderSubtle
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            spacing: 8

            // Progress Slider & Times
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                spacing: 12

                Text {
                    text: root.formatTime(backend.position)
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                }

                Slider {
                    id: bottomSlider
                    width: parent.width - 40 - 40 - 24
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: Math.max(1, backend.duration)
                    value: backend.position

                    background: Rectangle {
                        x: bottomSlider.leftPadding
                        y: bottomSlider.topPadding + bottomSlider.availableHeight / 2 - height / 2
                        width: bottomSlider.availableWidth
                        height: 5
                        radius: 2.5
                        color: Theme.border

                        Rectangle {
                            width: bottomSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.accent
                            radius: 2.5
                        }
                    }

                    handle: Rectangle {
                        x: bottomSlider.leftPadding + bottomSlider.visualPosition * (bottomSlider.availableWidth - width)
                        y: bottomSlider.topPadding + bottomSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: bottomSlider.pressed ? Theme.accentHover : "#FFFFFF"
                        border.color: Theme.accent
                        border.width: 2
                    }

                    onMoved: {
                        backend.seek(bottomSlider.value)
                    }
                }

                Text {
                    text: root.formatTime(backend.duration)
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                }
            }

            // Buttons Row
            Item {
                width: parent.width
                height: 48

                // Center Playback Buttons
                Row {
                    anchors.centerIn: parent
                    spacing: 20

                    // Play Mode Toggle with PlayModeIcon
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: imModeMouse.containsMouse ? Theme.bgCardHover : "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        PlayModeIcon {
                            anchors.centerIn: parent
                            mode: backend.playMode
                            iconColor: imModeMouse.containsMouse ? Theme.accent : Theme.textSecondary
                        }

                        MouseArea {
                            id: imModeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setPlayMode((backend.playMode + 1) % 4)
                        }

                        ToolTip.visible: imModeMouse.containsMouse
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

                    // Previous Track (Vector Canvas)
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: imPrevMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                        border.color: imPrevMouse.containsMouse ? Theme.accent : Theme.border
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Canvas {
                            id: imPrevCanvas
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = imPrevMouse.containsMouse ? Theme.accent : Theme.textPrimary;
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
                                function onThemeModeChanged() { imPrevCanvas.requestPaint() }
                            }
                        }

                        MouseArea {
                            id: imPrevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: imPrevCanvas.requestPaint()
                            onExited: imPrevCanvas.requestPaint()
                            onClicked: backend.previousTrack()
                        }

                        ToolTip.visible: imPrevMouse.containsMouse
                        ToolTip.text: "上一首"
                    }

                    // Play / Pause (Vector Canvas)
                    Rectangle {
                        width: 50
                        height: 50
                        radius: 25
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: imPlayMouse.containsMouse ? Theme.accentHover : Theme.accentGradientStart }
                            GradientStop { position: 1.0; color: imPlayMouse.containsMouse ? Theme.accentHover : Theme.accentGradientEnd }
                        }
                        anchors.verticalCenter: parent.verticalCenter

                        Canvas {
                            id: imPlayCanvas
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
                                function onPlaybackStateChanged() { imPlayCanvas.requestPaint() }
                            }
                        }

                        MouseArea {
                            id: imPlayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.playPause()
                        }

                        ToolTip.visible: imPlayMouse.containsMouse
                        ToolTip.text: backend.isPlaying ? "暂停" : "播放"
                    }

                    // Next Track (Vector Canvas)
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: imNextMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                        border.color: imNextMouse.containsMouse ? Theme.accent : Theme.border
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Canvas {
                            id: imNextCanvas
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = imNextMouse.containsMouse ? Theme.accent : Theme.textPrimary;
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
                                function onThemeModeChanged() { imNextCanvas.requestPaint() }
                            }
                        }

                        MouseArea {
                            id: imNextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: imNextCanvas.requestPaint()
                            onExited: imNextCanvas.requestPaint()
                            onClicked: backend.nextTrack()
                        }

                        ToolTip.visible: imNextMouse.containsMouse
                        ToolTip.text: "下一首"
                    }

                    // Stop (Vector Canvas)
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: imStopMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                        border.color: imStopMouse.containsMouse ? Theme.accent : Theme.border
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Canvas {
                            id: imStopCanvas
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = imStopMouse.containsMouse ? "#EF4444" : Theme.textPrimary;
                                // Rounded-like square
                                ctx.fillRect(3, 3, 10, 10);
                            }

                            Connections {
                                target: Theme
                                function onThemeModeChanged() { imStopCanvas.requestPaint() }
                            }
                        }

                        MouseArea {
                            id: imStopMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: imStopCanvas.requestPaint()
                            onExited: imStopCanvas.requestPaint()
                            onClicked: backend.stop()
                        }

                        ToolTip.visible: imStopMouse.containsMouse
                        ToolTip.text: "停止播放"
                    }
                }

                // Right Volume Slider
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: backend.volume === 0 ? "🔇" : "🔊"
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Slider {
                        id: imVolSlider
                        width: 90
                        anchors.verticalCenter: parent.verticalCenter
                        from: 0
                        to: 100
                        value: backend.volume

                        background: Rectangle {
                            x: imVolSlider.leftPadding
                            y: imVolSlider.topPadding + imVolSlider.availableHeight / 2 - height / 2
                            width: imVolSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Theme.border

                            Rectangle {
                                width: imVolSlider.visualPosition * parent.width
                                height: parent.height
                                color: Theme.accent
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: imVolSlider.leftPadding + imVolSlider.visualPosition * (imVolSlider.availableWidth - width)
                            y: imVolSlider.topPadding + imVolSlider.availableHeight / 2 - height / 2
                            implicitWidth: 10
                            implicitHeight: 10
                            radius: 5
                            color: "#FFFFFF"
                            border.color: Theme.accent
                            border.width: 1
                        }

                        onMoved: backend.setVolume(imVolSlider.value)
                    }
                }
            }
        }
    }
}
