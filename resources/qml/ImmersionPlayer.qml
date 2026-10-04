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

        // ---------------- Left: Realistic Hi-Fi Vinyl Turntable ----------------
        Item {
            id: leftVinylArea
            width: parent.width * 0.46
            height: parent.height
            anchors.left: parent.left
            anchors.top: parent.top

            // Turntable Deck (唱片机机身机座)
            Item {
                id: turntableDeck
                width: Math.min(420, Math.min(leftVinylArea.width - 32, leftVinylArea.height - 32))
                height: width * 0.94
                anchors.centerIn: parent

                // Deck Outer Body with Drop Shadow & Brushed Bevel
                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: Theme.isDark ? "#12141C" : "#E2E8F0"
                    border.color: Theme.isDark ? "#2A3042" : "#CBD5E1"
                    border.width: 1.5

                    // Inner Chamfer Panel
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 17
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.isDark ? "#1E222F" : "#FFFFFF" }
                            GradientStop { position: 0.3; color: Theme.isDark ? "#161823" : "#F1F5F9" }
                            GradientStop { position: 1.0; color: Theme.isDark ? "#0F1118" : "#E2E8F0" }
                        }
                        border.color: Theme.isDark ? "#222736" : "#E2E8F0"
                        border.width: 1
                    }
                }

                // 4 Corner Metallic Mounting Rivets / Screws
                Repeater {
                    model: [
                        { x: 14, y: 14 },
                        { x: turntableDeck.width - 22, y: 14 },
                        { x: 14, y: turntableDeck.height - 22 },
                        { x: turntableDeck.width - 22, y: turntableDeck.height - 22 }
                    ]
                    delegate: Rectangle {
                        x: modelData.x
                        y: modelData.y
                        width: 8
                        height: 8
                        radius: 4
                        color: Theme.isDark ? "#333A4D" : "#94A3B8"
                        border.color: Theme.isDark ? "#4B556D" : "#64748B"
                        border.width: 1

                        Rectangle {
                            anchors.centerIn: parent
                            width: 2
                            height: 6
                            color: Theme.isDark ? "#1E222D" : "#475569"
                            rotation: (index * 45) % 90
                        }
                    }
                }

                // Top-Left Branding Text
                Row {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 24
                    anchors.topMargin: 20
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "HI-FI TURNTABLE DIRECT DRIVE"
                        color: Theme.isDark ? "#64748B" : "#94A3B8"
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1.2
                    }
                }

                // Bottom-Left Controls: Speed & Strobe Power Indicator
                Row {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 24
                    anchors.bottomMargin: 18
                    spacing: 12

                    // Strobe Power LED
                    Item {
                        width: 18
                        height: 18
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: 5
                            color: backend.isPlaying ? Theme.accent : "#475569"
                            border.color: backend.isPlaying ? "#FFFFFF" : "#334155"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            radius: 9
                            color: Theme.accent
                            opacity: backend.isPlaying ? 0.35 : 0
                            visible: backend.isPlaying
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: backend.isPlaying && root.opacity > 0
                                NumberAnimation { from: 0.2; to: 0.55; duration: 1100; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 0.55; to: 0.2; duration: 1100; easing.type: Easing.InOutQuad }
                            }
                        }
                    }

                    // 33 ⅓ RPM Speed Pill
                    Rectangle {
                        width: 68
                        height: 22
                        radius: 11
                        color: Theme.isDark ? "#1E2230" : "#E2E8F0"
                        border.color: Theme.isDark ? "#333A4D" : "#CBD5E1"
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "33 ⅓ RPM"
                            color: backend.isPlaying ? Theme.accent : Theme.textSecondary
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                // Right-Side Pitch Fader Track Accent
                Item {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 22
                    anchors.bottomMargin: 24
                    width: 16
                    height: 70

                    Rectangle {
                        anchors.centerIn: parent
                        width: 3
                        height: parent.height
                        radius: 1.5
                        color: Theme.isDark ? "#282D3D" : "#CBD5E1"
                    }

                    // Center Pitch Notch
                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 1
                        color: Theme.isDark ? "#4B556D" : "#94A3B8"
                    }

                    // Fader Knob
                    Rectangle {
                        x: (parent.width - width) / 2
                        y: parent.height * 0.45
                        width: 14
                        height: 7
                        radius: 2
                        color: Theme.isDark ? "#475569" : "#64748B"
                        border.color: Theme.isDark ? "#64748B" : "#94A3B8"
                        border.width: 1
                    }
                }

                // ---------------- Metallic Platter & Slipmat (金属铝合金转盘托盘) ----------------
                Rectangle {
                    id: platterRim
                    width: turntableDeck.width * 0.74
                    height: width
                    radius: width / 2
                    x: turntableDeck.width * 0.42 - width / 2
                    y: turntableDeck.height * 0.52 - height / 2
                    color: Theme.isDark ? "#1C202C" : "#CBD5E1"
                    border.color: Theme.isDark ? "#475569" : "#94A3B8"
                    border.width: 3

                    // Platter Strobe Rim Dots (Simulated metallic bezel)
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: width / 2
                        color: "transparent"
                        border.color: Theme.isDark ? "#2D3446" : "#E2E8F0"
                        border.width: 2
                    }

                    // Inner Platter Slipmat (深色抗静电毛毡唱垫)
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 14
                        height: width
                        radius: width / 2
                        color: Theme.isDark ? "#0D0E13" : "#1E293B"
                        border.color: Theme.isDark ? "#1C202C" : "#334155"
                        border.width: 1.5
                    }
                }

                // ---------------- Vinyl Record Disc (高质感黑胶唱片本体) ----------------
                Rectangle {
                    id: vinylDisc
                    width: platterRim.width - 20
                    height: width
                    radius: width / 2
                    anchors.centerIn: platterRim
                    color: "#0A0B0F"
                    border.color: "#1E222D"
                    border.width: 2

                    // Continuous Smooth Rotation (Pauses and resumes without jumping to 0)
                    NumberAnimation {
                        id: vinylSpinAnim
                        target: vinylDisc
                        property: "rotation"
                        from: 0
                        to: 360
                        duration: 20000
                        loops: Animation.Infinite
                        running: true
                        paused: !backend.isPlaying || root.opacity === 0
                    }

                    // Lead-in Outer Groove
                    Rectangle {
                        anchors.centerIn: parent
                        width: vinylDisc.width * 0.94
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.color: "#181B24"
                        border.width: 1
                    }

                    // Concentric High-Fidelity Music Grooves (音轨细纹)
                    Repeater {
                        model: [0.88, 0.82, 0.77, 0.71, 0.65, 0.59, 0.53]
                        delegate: Rectangle {
                            anchors.centerIn: parent
                            width: vinylDisc.width * modelData
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.color: "#1A1D27"
                            border.width: 1
                            opacity: index % 2 === 0 ? 0.7 : 0.4
                        }
                    }

                    // Run-Out Groove
                    Rectangle {
                        anchors.centerIn: parent
                        width: vinylDisc.width * 0.48
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.color: "#141720"
                        border.width: 2
                    }

                    // Center Label (中央纸质唱片标贴 & 专辑封面)
                    Rectangle {
                        id: albumCoverRec
                        width: vinylDisc.width * 0.40
                        height: width
                        radius: width / 2
                        anchors.centerIn: parent
                        clip: true
                        color: Theme.bgCard
                        border.color: "#D4AF37" // Elegant gold foil rim
                        border.width: 2

                        Image {
                            anchors.fill: parent
                            source: backend.currentSong.coverUrl ? backend.currentSong.coverUrl : "qrc:/icons/app.svg"
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        // Label Inner Shading
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.color: Qt.rgba(0, 0, 0, 0.3)
                            border.width: 3
                        }
                    }

                    // Center Spindle Hole & Metallic Pin
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: "#0A0B0E"
                        border.color: "#94A3B8"
                        border.width: 2
                        anchors.centerIn: parent

                        // Chrome Center Spindle Pin
                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: 5
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#FFFFFF" }
                                GradientStop { position: 0.5; color: "#CBD5E1" }
                                GradientStop { position: 1.0; color: "#64748B" }
                            }
                        }
                    }
                }

                // Vinyl Specular Glare / Sheen Overlay (真实黑胶扇形双向反光，固定于光照方向)
                Canvas {
                    id: vinylSheenCanvas
                    anchors.fill: vinylDisc
                    antialiasing: true
                    opacity: 0.22
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = width / 2 - 2;

                        function drawSheenWedge(a1, a2) {
                            ctx.save();
                            ctx.beginPath();
                            ctx.moveTo(cx, cy);
                            ctx.arc(cx, cy, r, a1, a2);
                            ctx.closePath();
                            var grad = ctx.createRadialGradient(cx, cy, r * 0.38, cx, cy, r);
                            grad.addColorStop(0, "rgba(255, 255, 255, 0.0)");
                            grad.addColorStop(0.5, "rgba(255, 255, 255, 0.5)");
                            grad.addColorStop(1.0, "rgba(255, 255, 255, 0.08)");
                            ctx.fillStyle = grad;
                            ctx.fill();
                            ctx.restore();
                        }
                        // Two opposing diagonal light reflections across grooves
                        drawSheenWedge(-Math.PI * 0.38, -Math.PI * 0.16);
                        drawSheenWedge(Math.PI * 0.62, Math.PI * 0.84);
                    }
                }

                // ---------------- Fixed Tonearm Cradle / Rest (机身上的唱臂托架) ----------------
                Item {
                    id: armRest
                    x: turntableDeck.width * 0.86
                    y: turntableDeck.height * 0.44
                    width: 14
                    height: 24

                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 16
                        radius: 2
                        color: Theme.isDark ? "#333A4D" : "#94A3B8"
                        border.color: Theme.isDark ? "#4B556D" : "#64748B"
                        border.width: 1
                    }
                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 12
                        height: 4
                        radius: 2
                        color: Theme.isDark ? "#475569" : "#64748B"
                    }
                }

                // ---------------- Realistic Gimbal Tonearm Assembly (高精细金属唱臂) ----------------
                Item {
                    id: tonearm
                    x: turntableDeck.width * 0.81
                    y: turntableDeck.height * 0.22
                    width: 70
                    height: 220
                    z: 30
                    transformOrigin: Item.TopLeft
                    // Dynamic Realistic Arm Swing: Lands gently on record (15°), lifts off to arm rest (-20°)
                    rotation: backend.isPlaying ? 15 : -20

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 750
                            easing.type: Easing.InOutCubic
                        }
                    }

                    // 1. Pivot Base Tower (圆台形双层金属轴承座)
                    Rectangle {
                        x: -18
                        y: -18
                        width: 36
                        height: 36
                        radius: 18
                        color: Theme.isDark ? "#1E222F" : "#CBD5E1"
                        border.color: Theme.isDark ? "#475569" : "#94A3B8"
                        border.width: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            radius: 11
                            color: Theme.isDark ? "#0F1118" : "#E2E8F0"
                            border.color: Theme.isDark ? "#64748B" : "#CBD5E1"
                            border.width: 1.5

                            Rectangle {
                                anchors.centerIn: parent
                                width: 8
                                height: 8
                                radius: 4
                                color: Theme.isDark ? "#94A3B8" : "#475569"
                            }
                        }
                    }

                    // 2. Counterweight (后置重锤，位于轴承上方)
                    Rectangle {
                        x: -10
                        y: -36
                        width: 20
                        height: 18
                        radius: 3
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#94A3B8" }
                            GradientStop { position: 0.5; color: "#CBD5E1" }
                            GradientStop { position: 1.0; color: "#64748B" }
                        }
                        border.color: "#475569"
                        border.width: 1

                        // Counterweight calibration markings
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: 2
                            color: "#334155"
                        }
                    }

                    // 3. S-Shaped Polished Metal Arm Wand (流线型金属唱臂杆)
                    Canvas {
                        id: armWandCanvas
                        x: -10
                        y: -6
                        width: 70
                        height: 190
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.lineWidth = 4.5;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";

                            var grad = ctx.createLinearGradient(0, 0, width, height);
                            grad.addColorStop(0, "#E2E8F0");
                            grad.addColorStop(0.5, "#CBD5E1");
                            grad.addColorStop(1, "#94A3B8");
                            ctx.strokeStyle = grad;

                            // S-curve shape: from pivot downwards, bending gently outward then into headshell
                            ctx.beginPath();
                            ctx.moveTo(10, 8);
                            ctx.bezierCurveTo(10, 50, 22, 100, 20, 140);
                            ctx.lineTo(16, 175);
                            ctx.stroke();
                        }
                    }

                    // 4. Cartridge Headshell & Stylus (黑胶唱头壳与金质唱针)
                    Item {
                        x: 8
                        y: 168
                        width: 24
                        height: 38
                        rotation: -8

                        // Cartridge Body
                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            color: Theme.isDark ? "#1E2433" : "#334155"
                            border.color: Theme.accent
                            border.width: 1.5

                            // Accent decorative line
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: 6
                                height: 2
                                color: Theme.accent
                            }

                            // Stylus Needle Tip (金质唱针尖)
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.bottomMargin: -3
                                anchors.leftMargin: 4
                                width: 3
                                height: 5
                                radius: 1
                                color: "#F59E0B"
                            }
                        }

                        // Finger Lift (唱头指提钩)
                        Rectangle {
                            x: parent.width - 2
                            y: 8
                            width: 10
                            height: 3
                            radius: 1.5
                            color: "#94A3B8"
                        }
                    }
                }

                // Interactive Click on Deck/Record to Play/Pause
                MouseArea {
                    id: deckMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.playPause()
                    z: 50
                }

                ToolTip.visible: deckMouseArea.containsMouse
                ToolTip.text: backend.isPlaying ? "点击唱机暂停播放" : "点击唱机开始播放"
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
