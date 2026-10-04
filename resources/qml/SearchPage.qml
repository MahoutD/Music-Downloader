import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: Theme.bgDark

    property int currentPlatform: 0
    property string currentKeyword: ""
    property int currentPage: 1
    property int totalCount: 0
    property bool isSearching: false
    property var searchResults: []
    property var hotWords: []
    property var selectedIndices: []

    signal showLyrics(string title, string artist, string lyrics)

    // Platform config: 0: Aggregated, 2: QQMusic, 1: NetEase, 3: KuGou, 4: Kuwo
    readonly property var platforms: [
        { name: "全部聚合", icon: "qrc:/icons/all.svg", color: "#8B5CF6", id: 0 },
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
        if (root.selectedIndices.length === root.searchResults.length) {
            root.selectedIndices = []
        } else {
            var arr = []
            for (var i = 0; i < root.searchResults.length; i++) {
                arr.push(i)
            }
            root.selectedIndices = arr
        }
    }

    function getSelectedSongs() {
        var list = []
        for (var i = 0; i < root.selectedIndices.length; i++) {
            var idx = root.selectedIndices[i]
            if (idx >= 0 && idx < root.searchResults.length) {
                list.push(root.searchResults[idx])
            }
        }
        return list
    }

    function getEffectivePlatform() {
        if (backend.currentSourceId === "all" || !backend.currentSourceId) return root.currentPlatform
        for (var i = 0; i < backend.sources.length; i++) {
            if (backend.sources[i].id === backend.currentSourceId) {
                return backend.sources[i].platform
            }
        }
        return root.currentPlatform
    }

    Connections {
        target: backend

        function onSearchFinished(success, songs, total, page) {
            root.isSearching = false
            root.selectedIndices = []
            if (success) {
                root.searchResults = songs
                root.totalCount = total
                root.currentPage = page
            } else {
                root.searchResults = []
                backend.showToast("搜索失败或未找到匹配歌曲", true)
            }
        }

        function onHotSearchFinished(words) {
            root.hotWords = words
        }
    }

    Component.onCompleted: {
        backend.getHotSearch(root.currentPlatform)
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
                    backend.previewLyrics(contextMenu.selectedSong)
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // 1. Top Bar: Platform Switcher Tabs + Active Sound Source Dropdown
        Item {
            width: parent.width
            height: 38

            // Left: Platform Switcher Tabs
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
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
                                backend.getHotSearch(modelData.id)
                                if (searchInput.text.trim().length > 0) {
                                    executeSearch(1)
                                }
                            }
                        }
                    }
                }
            }

            // Right: Sound Source Dropdown Selector (Requirement 7)
            Item {
                id: sourceSelectorItem
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 220
                height: 38

                Rectangle {
                    id: sourceBtn
                    anchors.fill: parent
                    radius: 19
                    color: Theme.bgCard
                    border.color: sourcePopup.visible ? Theme.accent : Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        width: parent.width - 24

                        Text { text: "🌐"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }

                        Text {
                            text: {
                                if (backend.currentSourceId === "all" || !backend.currentSourceId) return "音源: 全部聚合"
                                for (var i = 0; i < backend.sources.length; i++) {
                                    if (backend.sources[i].id === backend.currentSourceId) {
                                        return "音源: " + backend.sources[i].name
                                    }
                                }
                                return "音源: 默认"
                            }
                            color: Theme.textPrimary
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width - 36
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "▾"
                            color: Theme.textSecondary
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sourcePopup.visible = !sourcePopup.visible
                    }
                }

                Popup {
                    id: sourcePopup
                    y: sourceBtn.height + 4
                    x: sourceSelectorItem.width - width
                    width: 260
                    height: Math.min(310, (backend.sources.length + 1) * 38 + 60)
                    padding: 6
                    background: Rectangle {
                        color: Theme.bgCard
                        border.color: Theme.border
                        border.width: 1
                        radius: 8
                    }
                    contentItem: Column {
                        spacing: 4

                        ListView {
                            width: parent.width
                            height: Math.min(200, (backend.sources.length + 1) * 36)
                            clip: true
                            model: [{ id: "all", name: "全部聚合 (智能多源互补)", platform: 0 }].concat(backend.sources)
                            delegate: Rectangle {
                                width: parent.width
                                height: 36
                                radius: 4
                                color: (backend.currentSourceId === modelData.id) ? Theme.accent : (srcItemMouse.containsMouse ? Theme.bgCardHover : "transparent")

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: (backend.currentSourceId === modelData.id) ? "#FFFFFF" : Theme.textPrimary
                                    font.pixelSize: 11
                                    font.bold: backend.currentSourceId === modelData.id
                                    elide: Text.ElideRight
                                    width: parent.width - 24
                                }

                                MouseArea {
                                    id: srcItemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        backend.currentSourceId = modelData.id
                                        sourcePopup.visible = false
                                        if (modelData.id !== "all" && modelData.platform !== undefined) {
                                            root.currentPlatform = modelData.platform
                                        }
                                        if (searchInput.text.trim().length > 0) {
                                            executeSearch(1)
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.borderSubtle
                        }

                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: 4
                            color: updateSrcMouse.containsMouse ? Theme.bgCardHover : "transparent"

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "🔄"; font.pixelSize: 11 }
                                Text { text: "更新/刷新默认播放源"; color: Theme.accent; font.pixelSize: 11; font.bold: true }
                            }

                            MouseArea {
                                id: updateSrcMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    backend.updateDefaultSources()
                                    sourcePopup.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. Search Input Bar (Right-aligned Search Button)
        Rectangle {
            id: searchBarRec
            width: parent.width
            height: 48
            radius: 24
            color: Theme.bgInput
            border.color: searchInput.activeFocus ? Theme.accent : Theme.border
            border.width: 1

            // Left: Search Icon
            Text {
                id: searchIcon
                text: "🔍"
                font.pixelSize: 16
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
            }

            // Right: Search Button (Pin to right edge)
            Rectangle {
                id: searchBtn
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                width: 96
                height: 38
                radius: 19
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.accentGradientStart }
                    GradientStop { position: 1.0; color: Theme.accentGradientEnd }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.isSearching ? "搜索中..." : "搜索"
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.isSearching
                    onClicked: executeSearch(1)
                }
            }

            // Clear Button
            Rectangle {
                id: clearBtn
                visible: searchInput.text.length > 0
                anchors.right: searchBtn.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                radius: 12
                color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.textSecondary
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        searchInput.text = ""
                        searchInput.forceActiveFocus()
                    }
                }
            }

            // Middle: TextInput filling available space
            TextInput {
                id: searchInput
                anchors.left: searchIcon.right
                anchors.leftMargin: 12
                anchors.right: clearBtn.visible ? clearBtn.left : searchBtn.left
                anchors.rightMargin: 12
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: Theme.textPrimary
                font.pixelSize: 14
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                selectByMouse: true

                Text {
                    text: "搜索全网歌曲、歌手、专辑 (支持VIP/SQ无损解析)..."
                    color: Theme.textMuted
                    font.pixelSize: 14
                    visible: !searchInput.text && !searchInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                }

                Keys.onReturnPressed: executeSearch(1)
            }
        }

        // 3. Hot Search Words
        Row {
            width: parent.width
            spacing: 8
            visible: root.hotWords.length > 0 && root.searchResults.length === 0

            Text {
                text: "🔥 热门搜索:"
                color: Theme.textSecondary
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }

            Flow {
                width: parent.width - 90
                spacing: 6

                Repeater {
                    model: root.hotWords.slice(0, 8)
                    delegate: Rectangle {
                        height: 26
                        width: tagText.implicitWidth + 16
                        radius: 13
                        color: tagMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            id: tagText
                            anchors.centerIn: parent
                            text: modelData
                            color: Theme.textSecondary
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: tagMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = modelData
                                executeSearch(1)
                            }
                        }
                    }
                }
            }
        }

        // 4. Batch Operations Action Bar (Requirement 9)
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

        // 5. Search Results Header Table Bar
        Rectangle {
            width: parent.width
            height: 36
            color: Theme.bgHeader
            radius: 6
            visible: root.searchResults.length > 0

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
                        color: (root.selectedIndices.length > 0 && root.selectedIndices.length === root.searchResults.length) ? Theme.accent : Theme.bgInput
                        border.color: (root.selectedIndices.length > 0) ? Theme.accent : Theme.border
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#FFFFFF"
                            font.pixelSize: 10
                            visible: root.selectedIndices.length > 0 && root.selectedIndices.length === root.searchResults.length
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
                Text { text: "来源"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 85; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "操作"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // 6. Results ListView
        ListView {
            id: resultListView
            width: parent.width
            height: parent.height - (root.selectedIndices.length > 0 ? 280 : 230)
            clip: true
            model: root.searchResults
            spacing: 4

            delegate: Rectangle {
                id: songRow
                width: resultListView.width
                height: 52
                radius: 6
                color: root.isSelected(index) ? Theme.bgCardHover : (rowMouse.containsMouse ? Theme.bgCardHover : (index % 2 === 0 ? Theme.bgCardAlt : Theme.bgDark))
                border.color: root.isSelected(index) ? Theme.accent : (rowMouse.containsMouse ? Theme.border : "transparent")
                border.width: 1

                // Row-level mouse area for hover, double-click and right-click
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

                    // Checkbox + Index
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
                            color: Theme.textMuted
                            font.pixelSize: 11
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
                                    backend.previewLyrics(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Empty Search Placeholder
        Item {
            width: parent.width
            height: parent.height - 180
            visible: root.searchResults.length === 0 && !root.isSearching

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: "🎵"
                    font.pixelSize: 48
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "输入歌曲名或歌手，开启全网无损多线程音乐搜索"
                    color: Theme.textSecondary
                    font.pixelSize: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "支持 QQ音乐 / 网易云音乐 / 酷狗音乐 / 酷我音乐 VIP音源解析与试听下载"
                    color: Theme.textMuted
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // 7. Pagination Footer
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            visible: root.searchResults.length > 0

            Rectangle {
                width: 72
                height: 32
                radius: 6
                color: root.currentPage > 1 ? Theme.bgCard : Theme.bgCardAlt
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "上一页"
                    color: root.currentPage > 1 ? Theme.textPrimary : Theme.textMuted
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.currentPage > 1
                    onClicked: executeSearch(root.currentPage - 1)
                }
            }

            Text {
                text: "第 " + root.currentPage + " 页" + (root.totalCount > 0 ? " (共 " + root.totalCount + " 条结果)" : "")
                color: Theme.textSecondary
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 72
                height: 32
                radius: 6
                color: root.searchResults.length >= 20 ? Theme.bgCard : Theme.bgCardAlt
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "下一页"
                    color: root.searchResults.length >= 20 ? Theme.textPrimary : Theme.textMuted
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.searchResults.length >= 20
                    onClicked: executeSearch(root.currentPage + 1)
                }
            }
        }
    }

    function executeSearch(page) {
        var kw = searchInput.text.trim()
        if (kw.length === 0) return
        root.isSearching = true
        root.currentKeyword = kw
        root.currentPage = page
        var plat = getEffectivePlatform()
        backend.search(kw, plat, page, 20)
    }
}
