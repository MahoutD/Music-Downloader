import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: Theme.bgDark

    property string downloadDir: backend.downloadDir
    property int selectedQuality: backend.defaultQuality
    property bool downloadLyric: backend.downloadLyric
    property bool downloadCover: backend.downloadCover
    property int fileNameFormat: backend.fileNameFormat

    signal openAboutRequested()

    Connections {
        target: backend
        function onSettingsChanged() {
            root.downloadDir = backend.downloadDir
            root.selectedQuality = backend.defaultQuality
            root.downloadLyric = backend.downloadLyric
            root.downloadCover = backend.downloadCover
            root.fileNameFormat = backend.fileNameFormat
        }
    }

    ScrollView {
        id: settingsScroll
        anchors.fill: parent
        anchors.margins: 24
        clip: true

        Column {
            width: settingsScroll.width - 24
            spacing: 20

            // ================= 1. 外观与主题设置卡片 =================
            Rectangle {
                width: parent.width
                height: 120
                radius: 10
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Row {
                        spacing: 8
                        Text { text: "🎨"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: "界面主题与视觉风格"
                            color: Theme.textPrimary
                            font.pixelSize: 15
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

                    Row {
                        spacing: 12
                        Repeater {
                            model: [
                                { name: "🌙 深邃暗夜", mode: 0, color: "#3B82F6" },
                                { name: "🟢 QQ音乐绿", mode: 1, color: "#10B981" },
                                { name: "🔴 网易云红", mode: 2, color: "#EF4444" },
                                { name: "☀️ 简约晨曦", mode: 3, color: "#64748B" }
                            ]
                            delegate: Rectangle {
                                height: 34
                                width: tName.implicitWidth + 24
                                radius: 17
                                color: Theme.themeMode === modelData.mode ? modelData.color : Theme.bgCardHover
                                border.color: Theme.themeMode === modelData.mode ? modelData.color : Theme.border
                                border.width: 1

                                Text {
                                    id: tName
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: Theme.themeMode === modelData.mode ? "#FFFFFF" : Theme.textPrimary
                                    font.pixelSize: 12
                                    font.bold: Theme.themeMode === modelData.mode
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Theme.setTheme(modelData.mode)
                                }
                            }
                        }
                    }
                }
            }

            // ================= 2. 下载选项卡片 =================
            Rectangle {
                width: parent.width
                height: 290
                radius: 10
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    // Header
                    Row {
                        spacing: 8
                        Text { text: "⚙️"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: "下载设置"
                            color: Theme.textPrimary
                            font.pixelSize: 15
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

                    // Row 1: Download Directory with Clear Layout
                    Item {
                        width: parent.width
                        height: 38

                        Text {
                            text: "下载保存目录:"
                            color: Theme.textSecondary
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 100
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 105
                            anchors.right: browseBtn.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            height: 36
                            radius: 6
                            color: Theme.bgInput
                            border.color: Theme.border
                            border.width: 1
                            clip: true

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                text: root.downloadDir && root.downloadDir.length > 0 ? root.downloadDir : "默认系统音乐目录"
                                color: Theme.textPrimary
                                font.pixelSize: 12
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            id: browseBtn
                            width: 90
                            height: 36
                            radius: 6
                            anchors.right: openDirBtn.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "选择目录..."
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var dir = backend.chooseDirectory()
                                    if (dir && dir.length > 0) {
                                        root.downloadDir = dir
                                        backend.saveSettings(dir, root.selectedQuality, root.downloadLyric, root.downloadCover, root.fileNameFormat)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: openDirBtn
                            width: 90
                            height: 36
                            radius: 6
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.bgCardHover
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "打开目录"
                                color: Theme.textPrimary
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.openDownloadDirectory()
                            }
                        }
                    }

                    // Row 2: Default Quality
                    Item {
                        width: parent.width
                        height: 36

                        Text {
                            text: "默认优先音质:"
                            color: Theme.textSecondary
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 100
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 105
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Repeater {
                                model: [
                                    { name: "无损 SQ (FLAC)", val: 0 },
                                    { name: "极高 HQ (320k)", val: 1 },
                                    { name: "标准 (128k)", val: 2 }
                                ]
                                delegate: Rectangle {
                                    height: 32
                                    width: qBtnTxt.implicitWidth + 24
                                    radius: 16
                                    color: root.selectedQuality === modelData.val ? Theme.accent : Theme.bgCardHover
                                    border.color: root.selectedQuality === modelData.val ? Theme.accent : Theme.border
                                    border.width: 1

                                    Text {
                                        id: qBtnTxt
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        color: root.selectedQuality === modelData.val ? "#FFFFFF" : Theme.textPrimary
                                        font.pixelSize: 12
                                        font.bold: root.selectedQuality === modelData.val
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedQuality = modelData.val
                                    }
                                }
                            }
                        }
                    }

                    // Row 3: Lyric & Cover Toggles
                    Item {
                        width: parent.width
                        height: 36

                        Text {
                            text: "附加元数据:"
                            color: Theme.textSecondary
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 100
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 105
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 24

                            // Lyric Checkbox
                            Row {
                                spacing: 8
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: root.downloadLyric ? Theme.accent : Theme.bgInput
                                    border.color: root.downloadLyric ? Theme.accent : Theme.border
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        visible: root.downloadLyric
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.downloadLyric = !root.downloadLyric
                                    }
                                }

                                Text {
                                    text: "下载同时保存歌词文件 (.lrc)"
                                    color: Theme.textPrimary
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Cover Checkbox
                            Row {
                                spacing: 8
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: root.downloadCover ? Theme.accent : Theme.bgInput
                                    border.color: root.downloadCover ? Theme.accent : Theme.border
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        visible: root.downloadCover
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.downloadCover = !root.downloadCover
                                    }
                                }

                                Text {
                                    text: "下载同时保存高清封面 (.jpg)"
                                    color: Theme.textPrimary
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Save Button
                    Item {
                        width: parent.width
                        height: 36

                        Rectangle {
                            height: 36
                            width: 120
                            radius: 18
                            anchors.right: parent.right
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Theme.accentGradientStart }
                                GradientStop { position: 1.0; color: Theme.accentGradientEnd }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "保存下载设置"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    backend.saveSettings(root.downloadDir, root.selectedQuality, root.downloadLyric, root.downloadCover, root.fileNameFormat)
                                }
                            }
                        }
                    }
                }
            }

            // ================= 3. 音源管理卡片 (导入、导出、默认音源) =================
            Rectangle {
                width: parent.width
                height: 470
                radius: 10
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    // Card Header with Action Buttons
                    Item {
                        width: parent.width
                        height: 44

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            Text { text: "🌐"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    text: "音源解析与数据源管理"
                                    color: Theme.textPrimary
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: "系统已默认内置酷我/QQ/网易云/酷狗高可用VIP音源，支持导出备份及导入自定义规则"
                                    color: Theme.textMuted
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // Export, Import, Reset Action Buttons
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            // 1. 导出配置
                            Rectangle {
                                height: 34
                                width: 110
                                radius: 6
                                color: "#0284C7"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "📤"; font.pixelSize: 11 }
                                    Text { text: "导出音源配置"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var path = backend.chooseFileDialog(true)
                                        if (path && path.length > 0) {
                                            backend.exportSources(path)
                                        }
                                    }
                                }
                            }

                            // 2. 导入配置
                            Rectangle {
                                height: 34
                                width: 110
                                radius: 6
                                color: "#059669"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "📥"; font.pixelSize: 11 }
                                    Text { text: "导入音源配置"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var path = backend.chooseFileDialog(false)
                                        if (path && path.length > 0) {
                                            backend.importSources(path)
                                        }
                                    }
                                }
                            }

                            // 3. 更新默认播放源 (Requirement 2)
                            Rectangle {
                                height: 34
                                width: 110
                                radius: 6
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Theme.accentGradientStart }
                                    GradientStop { position: 1.0; color: Theme.accentGradientEnd }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "🔄"; font.pixelSize: 11 }
                                    Text { text: "更新播放源"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.updateDefaultSources()
                                }
                            }

                            // 4. 恢复默认音源
                            Rectangle {
                                height: 34
                                width: 100
                                radius: 6
                                color: Theme.bgCardHover
                                border.color: Theme.border
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "⏮"; font.pixelSize: 11 }
                                    Text { text: "恢复默认"; color: Theme.textPrimary; font.pixelSize: 12 }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.resetDefaultSources()
                                }
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

                    // Active Selected Source Dropdown Row
                    Item {
                        width: parent.width
                        height: 38

                        Text {
                            text: "当前激活优先音源:"
                            color: Theme.textSecondary
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 130
                        }

                        Rectangle {
                            id: setSourceBtn
                            anchors.left: parent.left
                            anchors.leftMargin: 135
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 36
                            radius: 6
                            color: Theme.bgInput
                            border.color: setSourcePopup.visible ? Theme.accent : Theme.border
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text { text: "🌐"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }

                                Text {
                                    text: {
                                        if (backend.currentSourceId === "all" || !backend.currentSourceId) return "全部聚合 (智能多源互补解析)"
                                        for (var i = 0; i < backend.sources.length; i++) {
                                            if (backend.sources[i].id === backend.currentSourceId) {
                                                return backend.sources[i].name + " (" + backend.sources[i].id + ")"
                                            }
                                        }
                                        return "默认官方音源"
                                    }
                                    color: Theme.textPrimary
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width - 50
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "▾"
                                    color: Theme.textSecondary
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: setSourcePopup.visible = !setSourcePopup.visible
                            }

                            Popup {
                                id: setSourcePopup
                                y: setSourceBtn.height + 4
                                width: setSourceBtn.width
                                height: Math.min(260, (backend.sources.length + 1) * 38 + 16)
                                padding: 6
                                background: Rectangle {
                                    color: Theme.bgCard
                                    border.color: Theme.border
                                    border.width: 1
                                    radius: 8
                                }
                                contentItem: ListView {
                                    clip: true
                                    model: [{ id: "all", name: "全部聚合 (智能多源互补解析)" }].concat(backend.sources)
                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 36
                                        radius: 4
                                        color: (backend.currentSourceId === modelData.id) ? Theme.accent : (setItemMouse.containsMouse ? Theme.bgCardHover : "transparent")

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name
                                            color: (backend.currentSourceId === modelData.id) ? "#FFFFFF" : Theme.textPrimary
                                            font.pixelSize: 12
                                            font.bold: backend.currentSourceId === modelData.id
                                        }

                                        MouseArea {
                                            id: setItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                backend.currentSourceId = modelData.id
                                                setSourcePopup.visible = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Source Table Header
                    Rectangle {
                        width: parent.width
                        height: 32
                        color: Theme.bgHeader
                        radius: 4

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text { text: "平台"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 120; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "音源名称 / 标识"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 220; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "接口描述与特性"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 280; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "默认属性"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 90; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "状态 / 开关"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // Source ListView
                    ListView {
                        width: parent.width
                        height: 250
                        clip: true
                        model: backend.sources
                        spacing: 6

                        delegate: Rectangle {
                            width: parent.width
                            height: 48
                            radius: 6
                            color: sRowMouse.containsMouse ? Theme.bgCardHover : Theme.bgCardAlt
                            border.color: sRowMouse.containsMouse ? Theme.border : "transparent"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // Platform Badge (PlatformType: 1:NetEase, 2:QQ, 3:KuGou, 4:Kuwo)
                                Row {
                                    width: 120
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6

                                    Image {
                                        width: 16
                                        height: 16
                                        source: {
                                            switch (modelData.platform) {
                                                case 1: return "qrc:/icons/netease.svg"
                                                case 2: return "qrc:/icons/qq.svg"
                                                case 3: return "qrc:/icons/kugou.svg"
                                                case 4: return "qrc:/icons/kuwo.svg"
                                                default: return "qrc:/icons/app.svg"
                                            }
                                        }
                                        fillMode: Image.PreserveAspectFit
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: {
                                            switch (modelData.platform) {
                                                case 1: return "网易云音乐"
                                                case 2: return "QQ音乐"
                                                case 3: return "酷狗音乐"
                                                case 4: return "酷我音乐"
                                                default: return "通用音源"
                                            }
                                        }
                                        color: Theme.textPrimary
                                        font.pixelSize: 12
                                        font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Source Name
                                Column {
                                    width: 220
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: modelData.name
                                        color: Theme.textPrimary
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        text: "ID: " + modelData.id
                                        color: Theme.textMuted
                                        font.pixelSize: 10
                                    }
                                }

                                // Description
                                Text {
                                    text: modelData.description
                                    color: Theme.textSecondary
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: 280
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Built-in Badge
                                Rectangle {
                                    width: 74
                                    height: 20
                                    radius: 3
                                    color: modelData.type === "builtin" ? "#065F46" : "#374151"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.type === "builtin" ? "默认内置" : "用户自定义"
                                        color: modelData.type === "builtin" ? "#34D399" : "#9CA3AF"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                // Enable/Disable Switch
                                Row {
                                    spacing: 8
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 40
                                        height: 22
                                        radius: 11
                                        color: modelData.enabled ? "#10B981" : "#475569"

                                        Rectangle {
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: "#FFFFFF"
                                            x: modelData.enabled ? 20 : 2
                                            anchors.verticalCenter: parent.verticalCenter

                                            Behavior on x {
                                                NumberAnimation { duration: 150 }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: backend.toggleSource(modelData.id, !modelData.enabled)
                                        }
                                    }

                                    Text {
                                        text: modelData.enabled ? "已启用" : "已停用"
                                        color: modelData.enabled ? "#10B981" : Theme.textMuted
                                        font.pixelSize: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            MouseArea {
                                id: sRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }

            // ================= 4. 关于与使用声明卡片 (按钮弹出窗口模式) =================
            Rectangle {
                width: parent.width
                height: 76
                radius: 10
                color: Theme.bgCard
                border.color: Theme.border
                border.width: 1

                Item {
                    anchors.fill: parent
                    anchors.margins: 18

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 8
                            color: Theme.bgCardHover
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "ℹ️"
                                font.pixelSize: 20
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Row {
                                spacing: 8
                                Text {
                                    text: "关于 Music Downloader 与使用声明"
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                Text {
                                    text: "v2.0.0"
                                    color: Theme.accent
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            Text {
                                text: "严格5线程并发安全机制、全网音源解析技术说明与使用免责条款"
                                color: Theme.textSecondary
                                font.pixelSize: 11
                            }
                        }
                    }

                    // 查看关于信息按钮
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 130
                        height: 36
                        radius: 18
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.accentGradientStart }
                            GradientStop { position: 1.0; color: Theme.accentGradientEnd }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "查看关于信息"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            Text {
                                text: "↗"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openAboutRequested()
                        }
                    }
                }
            }
        }
    }
}
