import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: Theme.bgDark

    // Styled Right-Click Context Menu (Only 打开所在目录 and 删除任务)
    Menu {
        id: contextMenu
        property var selectedTask: null

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
            text: "📁 打开所在目录"
            onTriggered: backend.openDownloadDirectory()
        }

        MenuItem {
            text: "🗑 删除任务"
            onTriggered: {
                if (contextMenu.selectedTask) backend.removeTask(contextMenu.selectedTask.taskId)
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // 1. Download Control Header Card
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
                        GradientStop { position: 0.0; color: "#10B981" }
                        GradientStop { position: 1.0; color: "#059669" }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "📥"
                        font.pixelSize: 22
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Row {
                        spacing: 8
                        Text {
                            text: "下载任务管理器"
                            color: Theme.textPrimary
                            font.pixelSize: 16
                            font.bold: true
                        }

                        // Concurrency Badge (max 5 threads)
                        Rectangle {
                            height: 20
                            width: concText.implicitWidth + 12
                            radius: 10
                            color: backend.activeDownloadsCount > 0 ? "#10B981" : Theme.bgCardHover
                            border.color: Theme.border
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: concText
                                anchors.centerIn: parent
                                text: "并发: " + backend.activeDownloadsCount + " / 5 线程"
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: "多线程异步下载 | 支持断点续传与无损音质"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                    }
                }
            }

            // Action Buttons
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // 全部开始
                Rectangle {
                    height: 34
                    width: 88
                    radius: 6
                    color: "#2563EB"

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "▶"; color: "#FFFFFF"; font.pixelSize: 10 }
                        Text { text: "全部开始"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.startAllDownloads()
                    }
                }

                // 全部暂停
                Rectangle {
                    height: 34
                    width: 88
                    radius: 6
                    color: Theme.bgCardHover
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "⏸"; color: Theme.textPrimary; font.pixelSize: 10 }
                        Text { text: "全部暂停"; color: Theme.textPrimary; font.pixelSize: 12; font.bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.pauseAllDownloads()
                    }
                }

                // 清空已完成
                Rectangle {
                    height: 34
                    width: 96
                    radius: 6
                    color: Theme.bgCardHover
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "🗑"; font.pixelSize: 11 }
                        Text { text: "清空已完成"; color: Theme.textPrimary; font.pixelSize: 12 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.clearCompletedDownloads()
                    }
                }

                // 打开下载目录
                Rectangle {
                    height: 34
                    width: 104
                    radius: 6
                    color: "#059669"

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "📁"; font.pixelSize: 11 }
                        Text { text: "打开下载目录"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.openDownloadDirectory()
                    }
                }
            }
        }

        // 2. Task List Header
        Rectangle {
            width: parent.width
            height: 36
            color: Theme.bgHeader
            radius: 6
            visible: backend.downloadTasks.length > 0

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text { text: "歌曲信息"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 280; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "音质/平台"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 140; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "下载进度"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 220; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "状态 / 速度"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; width: 140; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "操作"; color: Theme.textMuted; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // 3. Task ListView
        ListView {
            id: taskListView
            width: parent.width
            height: parent.height - 140
            clip: true
            model: backend.downloadTasks
            spacing: 6

            delegate: Rectangle {
                id: taskRow
                width: taskListView.width
                height: 64
                radius: 6
                color: rMouse.containsMouse ? Theme.bgCardHover : Theme.bgCardAlt
                border.color: rMouse.containsMouse ? Theme.border : "transparent"
                border.width: 1

                // MouseArea for row events
                MouseArea {
                    id: rMouse
                    anchors.fill: parent
                    z: 1
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            contextMenu.selectedTask = modelData
                            contextMenu.popup()
                        }
                    }
                    onDoubleClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton && modelData.statusCode === 3) {
                            backend.openAudioFile(modelData.audioFilePath)
                        }
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    z: 2

                    // Song Info
                    Row {
                        width: 280
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Rectangle {
                            width: 44
                            height: 44
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
                            width: parent.width - 54

                            Text {
                                text: modelData.title
                                color: Theme.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.artist
                                color: Theme.textSecondary
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    // Quality & Platform Badges
                    Row {
                        width: 140
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Rectangle {
                            height: 20
                            width: qTxt.implicitWidth + 8
                            radius: 3
                            color: "#0284C7"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: qTxt
                                anchors.centerIn: parent
                                text: modelData.qualityName ? modelData.qualityName : "标准"
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        Rectangle {
                            height: 20
                            width: pTxt.implicitWidth + 8
                            radius: 3
                            color: modelData.platformColor ? modelData.platformColor : Theme.accent
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: pTxt
                                anchors.centerIn: parent
                                text: modelData.platformName ? modelData.platformName : ""
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    // Progress Bar
                    Column {
                        width: 220
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Theme.bgCard

                            Rectangle {
                                width: parent.width * Math.min(1.0, Math.max(0.0, modelData.progress / 100.0))
                                height: parent.height
                                radius: 3
                                color: modelData.statusCode === 3 ? "#10B981" : (modelData.statusCode === 4 ? "#EF4444" : Theme.accent)
                            }
                        }

                        Item {
                            width: parent.width
                            height: 14
                            Text {
                                text: modelData.sizeText ? modelData.sizeText : ""
                                color: Theme.textMuted
                                font.pixelSize: 10
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.progress + "%"
                                color: Theme.textSecondary
                                font.pixelSize: 10
                                font.bold: true
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Status & Speed
                    Column {
                        width: 140
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: modelData.statusText
                            color: {
                                switch (modelData.statusCode) {
                                    case 1: return Theme.accent // 下载中
                                    case 2: return "#F59E0B" // 已暂停
                                    case 3: return "#10B981" // 已完成
                                    case 4: return "#EF4444" // 失败
                                    default: return Theme.textSecondary // 等待
                                }
                            }
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: modelData.speedText ? modelData.speedText : ""
                            color: Theme.textMuted
                            font.pixelSize: 10
                            visible: modelData.statusCode === 1
                        }
                    }

                    // Action Buttons - z: 10
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        z: 10

                        // Pause / Resume
                        Rectangle {
                            visible: modelData.statusCode === 1 || modelData.statusCode === 2
                            height: 28
                            width: 54
                            radius: 4
                            color: modelData.statusCode === 1 ? Theme.bgCardHover : "#2563EB"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.statusCode === 1 ? "暂停" : "继续"
                                color: "#FFFFFF"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.statusCode === 1) {
                                        backend.pauseTask(modelData.taskId)
                                    } else {
                                        backend.resumeTask(modelData.taskId)
                                    }
                                }
                            }
                        }

                        // Play local audio (if finished)
                        Rectangle {
                            visible: modelData.statusCode === 3
                            height: 28
                            width: 52
                            radius: 4
                            color: "#10B981"

                            Text {
                                anchors.centerIn: parent
                                text: "播放"
                                color: "#FFFFFF"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.openAudioFile(modelData.audioFilePath)
                            }
                        }

                        // Delete
                        Rectangle {
                            height: 28
                            width: 48
                            radius: 4
                            color: Theme.bgCardHover
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "删除"
                                color: "#EF4444"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.removeTask(modelData.taskId)
                            }
                        }
                    }
                }
            }
        }

        // Empty State
        Item {
            width: parent.width
            height: parent.height - 140
            visible: backend.downloadTasks.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: "📥"
                    font.pixelSize: 48
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "暂无下载任务"
                    color: Theme.textSecondary
                    font.pixelSize: 15
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "在搜索或榜单页面点击「下载」或「批量下载」，任务将在此处显示"
                    color: Theme.textMuted
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
