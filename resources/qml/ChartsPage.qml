import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: Theme.bgDark

    // Default to QQ Music (id: 2)
    property int currentPlatform: 2
    property string currentChartId: ""
    property string currentChartName: ""
    property string currentChartDesc: ""
    property var chartList: []
    property var chartSongs: []
    property bool isLoading: false
    property var selectedIndices: []

    signal showLyrics(string title, string artist, string lyrics)

    // Platform config: 2: QQMusic, 1: NetEase, 3: KuGou, 4: Kuwo
    readonly property var platforms: [
        { name: "QQ音乐", icon: "qrc:/icons/qq.svg", color: "#10B981", id: 2 },
        { name: "网易云音乐", icon: "qrc:/icons/netease.svg", color: "#EF4444", id: 1 },
        { name: "酷狗音乐", icon: "qrc:/icons/kugou.svg", color: "#3B82F6", id: 3 },
        { name: "酷我音乐", icon: "qrc:/icons/kuwo.svg", color: "#F59E0B", id: 4 }
    ]

    function isSelected(idx) {
        return root.selectedIndices.indexOf(idx) !== -1
    }

    function toggleSelect(idx) {
        var arr = root.selectedIndices.slice()
        var pos = arr.indexOf(idx)
        if (pos !== -1) {
            arr.splice(pos, 1)
        } else {
            arr.push(idx)
        }
        root.selectedIndices = arr
    }

    function selectAll() {
        if (root.selectedIndices.length === root.chartSongs.length) {
            root.selectedIndices = []
        } else {
            var arr = []
            for (var i = 0; i < root.chartSongs.length; i++) {
                arr.push(i)
            }
            root.selectedIndices = arr
        }
    }

    function getSelectedSongs() {
        var list = []
        for (var i = 0; i < root.selectedIndices.length; i++) {
            var idx = root.selectedIndices[i]
            if (idx >= 0 && idx < root.chartSongs.length) {
                list.push(root.chartSongs[idx])
            }
        }
        return list
    }

    Connections {
        target: backend

        function onChartListFinished(charts) {
            root.chartList = charts
            root.selectedIndices = []
            if (charts.length > 0) {
                root.currentChartId = charts[0].id
                root.currentChartName = charts[0].name
                root.currentChartDesc = charts[0].description
                loadSongs(charts[0].id)
            }
        }

        function onChartSongsFinished(success, songs) {
            root.isLoading = false
            root.selectedIndices = []
            if (success) {
                root.chartSongs = songs
            } else {
                root.chartSongs = []
                backend.showToast("加载榜单歌曲失败", true)
            }
        }
    }

    Component.onCompleted: {
        backend.loadChartList(root.currentPlatform)
    }

    // Styled Right-Click Context Menu
    Menu {
        id: contextMenu
        property var selectedSong: null

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
                if (contextMenu.selectedSong) backend.playSong(contextMenu.selectedSong)
            }
        }
        MenuItem {
            text: "+ 添加到播放列表"
            onTriggered: {
                if (contextMenu.selectedSong) backend.addToPlaylist(contextMenu.selectedSong)
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
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // 1. Platform Switcher Tabs
        Row {
            spacing: 10
            Repeater {
                model: root.platforms
                delegate: Rectangle {
                    height: 38
                    width: platRow.implicitWidth + 24
                    radius: 19
                    color: root.currentPlatform === modelData.id ? modelData.color : Theme.bgCard
                    border.color: root.currentPlatform === modelData.id ? modelData.color : Theme.border
                    border.width: 1

                    Row {
                        id: platRow
                        anchors.centerIn: parent
                        spacing: 8

                        Image {
                            width: 18
                            height: 18
                            source: modelData.icon
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.name
                            color: root.currentPlatform === modelData.id ? "#FFFFFF" : Theme.textPrimary
                            font.pixelSize: 13
                            font.bold: root.currentPlatform === modelData.id
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentPlatform = modelData.id
                            backend.loadChartList(modelData.id)
                        }
                    }
                }
            }
        }

        // 2. Charts Categories Horizontal Scroll
        ScrollView {
            width: parent.width
            height: 42
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            Row {
                spacing: 8
                Repeater {
                    model: root.chartList
                    delegate: Rectangle {
                        height: 34
                        width: chartTagText.implicitWidth + 24
                        radius: 17
                        color: root.currentChartId === modelData.id ? Theme.accent : (cMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard)
                        border.color: root.currentChartId === modelData.id ? Theme.accentHover : Theme.border
                        border.width: 1

                        Text {
                            id: chartTagText
                            anchors.centerIn: parent
                            text: modelData.name
                            color: root.currentChartId === modelData.id ? "#FFFFFF" : Theme.textPrimary
                            font.pixelSize: 12
                            font.bold: root.currentChartId === modelData.id
                        }

                        MouseArea {
                            id: cMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentChartId = modelData.id
                                root.currentChartName = modelData.name
                                root.currentChartDesc = modelData.description
                                loadSongs(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // 3. Chart Header Card
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
                spacing: 14

                Rectangle {
                    width: 44
                    height: 44
                    radius: 8
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#F59E0B" }
                        GradientStop { position: 1.0; color: "#EF4444" }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "🏆"
                        font.pixelSize: 22
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: root.currentChartName.length > 0 ? root.currentChartName : "热门音乐榜单"
                        color: Theme.textPrimary
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: root.currentChartDesc.length > 0 ? root.currentChartDesc : "实时抓取各大平台热门流行金曲"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                    }
                }
            }

            // Batch Actions: Play All, Download All
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // Play All
                Rectangle {
                    height: 36
                    width: 104
                    radius: 18
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accentGradientStart }
                        GradientStop { position: 1.0; color: Theme.accentGradientEnd }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "▶"; color: "#FFFFFF"; font.pixelSize: 11 }
                        Text { text: "播放全部"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.chartSongs.length > 0
                        onClicked: {
                            for (var i = 0; i < root.chartSongs.length; ++i) {
                                backend.addToPlaylist(root.chartSongs[i])
                            }
                            if (root.chartSongs.length > 0) {
                                backend.playSong(root.chartSongs[0])
                            }
                        }
                    }
                }

                // Download All
                Rectangle {
                    height: 36
                    width: 116
                    radius: 18
                    color: "#059669"

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "⬇"; color: "#FFFFFF"; font.pixelSize: 11 }
                        Text { text: "批量下载全部"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.chartSongs.length > 0
                        onClicked: {
                            backend.downloadBatch(root.chartSongs, -1)
                        }
                    }
                }
            }
        }

        // 4. Batch Operations Action Bar for Selected Songs (Requirement 9)
        Rectangle {
            width: parent.width
            height: 40
            radius: 8
            color: Theme.bgCardHover
            border.color: Theme.accent
            border.width: 1
            visible: root.selectedIndices.length > 0

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Text {
                    text: "✓ 已选择 " + root.selectedIndices.length + " 首歌曲"
                    color: Theme.accent
                    font.pixelSize: 12
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Batch Download Button
                Rectangle {
                    height: 28
                    width: 90
                    radius: 14
                    color: "#10B981"
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "⬇"; color: "#FFFFFF"; font.pixelSize: 10 }
                        Text { text: "批量下载"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var songs = root.getSelectedSongs()
                            backend.downloadBatch(songs, -1)
                            root.selectedIndices = []
                        }
                    }
                }

                // Batch Add to Playlist Button
                Rectangle {
                    height: 28
                    width: 105
                    radius: 14
                    color: "#3B82F6"
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "+"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                        Text { text: "批量加列表"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var songs = root.getSelectedSongs()
                            for (var i = 0; i < songs.length; i++) {
                                backend.addToPlaylist(songs[i])
                            }
                            backend.showToast("已将 " + songs.length + " 首歌曲加入播放列表", false)
                            root.selectedIndices = []
                        }
                    }
                }

                // Cancel Selection
                Text {
                    text: "取消选择"
                    color: Theme.textMuted
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedIndices = []
                    }
                }
            }
        }

        // 5. Table Header Bar
        Rectangle {
            width: parent.width
            height: 36
            color: Theme.bgHeader
            radius: 6

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // Select All Checkbox + #
                Row {
                    spacing: 6
                    width: 48
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 3
                        color: (root.selectedIndices.length > 0 && root.selectedIndices.length === root.chartSongs.length) ? Theme.accent : Theme.bgInput
                        border.color: (root.selectedIndices.length > 0) ? Theme.accent : Theme.border
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#FFFFFF"
                            font.pixelSize: 10
                            visible: root.selectedIndices.length > 0 && root.selectedIndices.length === root.chartSongs.length
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectAll()
                        }
                    }

                    Text { text: "#"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }

                Text { text: "歌曲名"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 280; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "歌手"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 140; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "专辑"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 140; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "时长"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 60; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "平台"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 85; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "操作"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // 6. Songs ListView
        ListView {
            id: chartListView
            width: parent.width
            height: parent.height - (root.selectedIndices.length > 0 ? 250 : 200)
            clip: true
            model: root.chartSongs
            spacing: 4

            delegate: Rectangle {
                id: songRow
                width: chartListView.width
                height: 52
                radius: 6
                color: root.isSelected(index) ? Theme.bgCardHover : (rowMouse.containsMouse ? Theme.bgCardHover : (index % 2 === 0 ? Theme.bgCardAlt : Theme.bgDark))
                border.color: root.isSelected(index) ? Theme.accent : (rowMouse.containsMouse ? Theme.border : "transparent")
                border.width: 1

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    z: 1
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onDoubleClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            backend.playSong(modelData)
                        }
                    }
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            contextMenu.selectedSong = modelData
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

                    // Checkbox + Rank
                    Row {
                        spacing: 6
                        width: 48
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 3
                            color: root.isSelected(index) ? Theme.accent : Theme.bgInput
                            border.color: root.isSelected(index) ? Theme.accent : Theme.border
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            z: 10

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                visible: root.isSelected(index)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleSelect(index)
                            }
                        }

                        Text {
                            text: (index + 1 < 10 ? "0" : "") + (index + 1)
                            color: index < 3 ? (index === 0 ? "#EF4444" : (index === 1 ? "#F59E0B" : "#10B981")) : Theme.textMuted
                            font.pixelSize: 12
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Song Info (Cover + Title + Tags)
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
                                    color: Theme.textPrimary
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
                        text: modelData.album ? modelData.album : "精选专辑"
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

                    // Source Platform Badge
                    Rectangle {
                        width: 76
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

                    // Action Buttons Row (试听, 列表, 下载, 歌词) - z: 10
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        z: 10

                        // 1. 试听
                        Rectangle {
                            height: 28
                            width: 58
                            radius: 4
                            color: btnPlayMouse.containsMouse ? "#2563EB" : "#1D4ED8"

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Text { text: "▷"; color: "#FFFFFF"; font.pixelSize: 11 }
                                Text { text: "试听"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                            }

                            MouseArea {
                                id: btnPlayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.playSong(modelData)
                            }
                        }

                        // 2. 加入列表
                        Rectangle {
                            height: 28
                            width: 58
                            radius: 4
                            color: btnAddMouse.containsMouse ? "#475569" : "#334155"

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Text { text: "+"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                                Text { text: "列表"; color: "#FFFFFF"; font.pixelSize: 11 }
                            }

                            MouseArea {
                                id: btnAddMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.addToPlaylist(modelData)
                            }
                        }

                        // 3. 下载
                        Rectangle {
                            height: 28
                            width: 58
                            radius: 4
                            color: btnDlMouse.containsMouse ? "#059669" : "#047857"

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Text { text: "⬇"; color: "#FFFFFF"; font.pixelSize: 10 }
                                Text { text: "下载"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                            }

                            MouseArea {
                                id: btnDlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.downloadSong(modelData, -1)
                            }
                        }

                        // 4. 歌词
                        Rectangle {
                            height: 28
                            width: 50
                            radius: 4
                            color: btnLrcMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "词"
                                color: btnLrcMouse.containsMouse ? Theme.accent : Theme.textSecondary
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: btnLrcMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    backend.fetchLyrics(modelData)
                                    root.showLyrics(modelData.title, modelData.artist, backend.currentLyrics)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function loadSongs(chartId) {
        root.isLoading = true
        root.selectedIndices = []
        backend.loadChartSongs(root.currentPlatform, chartId, 1, 30)
    }
}
