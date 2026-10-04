import QtQuick
import QtQuick.Controls

Window {
    id: root
    width: 780
    height: 120
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"
    visible: false

    property var lyricLines: []
    property int activeIndex: -1
    property string line1Text: "音乐下载器 - 桌面歌词"
    property string line2Text: "Music Downloader"
    property int lyricFontSize: 24
    property bool isLocked: false

    // Parse LRC strings into { timeMs, text }
    function parseLrc(lrcText) {
        var lines = []
        if (!lrcText || lrcText.trim().length === 0) {
            root.line1Text = backend.currentSong.title ? backend.currentSong.title : "暂无歌词"
            root.line2Text = backend.currentSong.artist ? backend.currentSong.artist : ""
            root.lyricLines = []
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
        updateLyrics(backend.position)
    }

    function updateLyrics(posMs) {
        if (!root.lyricLines || root.lyricLines.length === 0) {
            root.line1Text = backend.currentSong.title ? backend.currentSong.title : "暂无歌词"
            root.line2Text = backend.currentSong.artist ? backend.currentSong.artist : ""
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
            if (idx >= 0 && idx < root.lyricLines.length) {
                root.line1Text = root.lyricLines[idx].text
                root.line2Text = (idx + 1 < root.lyricLines.length) ? root.lyricLines[idx + 1].text : ""
            }
        }
    }

    Connections {
        target: backend
        function onLyricsChanged() {
            root.parseLrc(backend.currentLyrics)
        }
        function onPositionChanged() {
            root.updateLyrics(backend.position)
        }
        function onCurrentSongChanged() {
            root.parseLrc(backend.currentLyrics)
        }
    }

    Rectangle {
        id: bgRec
        anchors.fill: parent
        radius: 12
        color: dragArea.containsMouse ? "#CC0B0F19" : "transparent"
        border.color: dragArea.containsMouse && !root.isLocked ? "#334155" : "transparent"
        border.width: 1

        // Floating Control Bar on Hover
        Row {
            visible: dragArea.containsMouse
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            spacing: 8
            z: 100

            // Font smaller
            Rectangle {
                width: 22; height: 22; radius: 11; color: "#334155"
                Text { anchors.centerIn: parent; text: "A-"; color: "#FFFFFF"; font.pixelSize: 10 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.lyricFontSize = Math.max(16, root.lyricFontSize - 2)
                }
            }

            // Font bigger
            Rectangle {
                width: 22; height: 22; radius: 11; color: "#334155"
                Text { anchors.centerIn: parent; text: "A+"; color: "#FFFFFF"; font.pixelSize: 10 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.lyricFontSize = Math.min(36, root.lyricFontSize + 2)
                }
            }

            // Lock / Unlock
            Rectangle {
                width: 22; height: 22; radius: 11; color: root.isLocked ? "#EF4444" : "#334155"
                Text { anchors.centerIn: parent; text: root.isLocked ? "🔒" : "🔓"; font.pixelSize: 10 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.isLocked = !root.isLocked
                }
            }

            // Close
            Rectangle {
                width: 22; height: 22; radius: 11; color: "#334155"
                Text { anchors.centerIn: parent; text: "✕"; color: "#FFFFFF"; font.pixelSize: 10 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.visible = false
                }
            }
        }

        // Lyrics Text Display
        Column {
            anchors.centerIn: parent
            width: parent.width - 40
            spacing: 6

            Text {
                width: parent.width
                text: root.line1Text
                color: Theme.accent
                font.pixelSize: root.lyricFontSize
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: "#000000"
            }

            Text {
                width: parent.width
                text: root.line2Text
                color: "#E2E8F0"
                font.pixelSize: Math.max(14, root.lyricFontSize - 6)
                font.bold: false
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: "#000000"
            }
        }

        // Draggable MouseArea
        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: !root.isLocked
            property point clickPos: "0,0"

            onPressed: function(mouse) {
                clickPos = Qt.point(mouse.x, mouse.y)
            }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                    root.setX(root.x + delta.x)
                    root.setY(root.y + delta.y)
                }
            }
        }
    }
}
