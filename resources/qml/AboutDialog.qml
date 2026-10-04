import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    visible: opacity > 0
    opacity: 0
    color: Theme.bgCard
    radius: 12
    border.color: Theme.border
    border.width: 1
    width: 480
    height: 400
    z: 9999

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // Header
        Item {
            width: parent.width
            height: 40

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accentGradientStart }
                        GradientStop { position: 1.0; color: Theme.accentGradientEnd }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: "qrc:/icons/app.svg"
                        fillMode: Image.PreserveAspectFit
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: "关于 Music Downloader"
                        color: Theme.textPrimary
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        text: "版本 v2.0.0 (Qt Quick/QML 现代重构版)"
                        color: Theme.accent
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: closeMouse.containsMouse ? Theme.bgCardHover : "transparent"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.close()
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

        // Content
        Column {
            width: parent.width
            spacing: 12

            Text {
                text: "✨ 核心技术亮点与特性"
                color: Theme.textPrimary
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                text: "• 多线程并发引擎: 严格限制最大 5 线程并发异步下载，保障极速下载体验同时防止超频触发官方接口封禁。"
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
                width: parent.width
                lineHeight: 1.4
            }

            Text {
                text: "• 全网聚合音源: 支持 QQ音乐、网易云音乐、酷狗音乐、酷我音乐等主流平台 VIP / FLAC 无损 / 320k 高品质音频解析。"
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
                width: parent.width
                lineHeight: 1.4
            }

            Text {
                text: "• 现代化 Qt Quick/QML: 流体式极简深浅色主题，支持桌面悬浮歌词与黑胶唱片沉浸播放。"
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
                width: parent.width
                lineHeight: 1.4
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.borderSubtle }

        // Disclaimer
        Text {
            text: "⚠️ 免责声明: 本软件所有资源均来自公开互联网接口，仅供个人技术研究与学习交流使用。请在下载后 24 小时内删除，尊重版权支持正版流媒体服务。"
            color: Theme.textMuted
            font.pixelSize: 11
            wrapMode: Text.Wrap
            width: parent.width
            lineHeight: 1.4
        }
    }

    function open() { root.opacity = 1 }
    function close() { root.opacity = 0 }
}
