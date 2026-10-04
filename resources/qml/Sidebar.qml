import QtQuick

Rectangle {
    id: root
    width: 220
    color: Theme.bgSidebar
    border.color: Theme.borderSubtle
    border.width: 1

    property int currentIndex: 0
    signal tabSelected(int index)

    // App Branding Header
    Rectangle {
        id: brandArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        color: "transparent"

        Row {
            anchors.centerIn: parent
            spacing: 10

            Rectangle {
                width: 38
                height: 38
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.accentGradientStart }
                    GradientStop { position: 1.0; color: Theme.accentGradientEnd }
                }

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: "qrc:/icons/app.svg"
                    fillMode: Image.PreserveAspectFit
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "音乐下载器"
                    color: Theme.textPrimary
                    font.pixelSize: 15
                    font.bold: true
                }

                Text {
                    text: "Music Downloader"
                    color: Theme.textMuted
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 1
            color: Theme.borderSubtle
        }
    }

    // Navigation Menu List
    Column {
        anchors.top: brandArea.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 6

        // Nav Items
        Repeater {
            model: [
                { name: "音乐搜索", icon: "🔍", index: 0 },
                { name: "热门榜单", icon: "🔥", index: 1 },
                { name: "下载管理", icon: "📥", index: 2 },
                { name: "播放列表", icon: "🎵", index: 3 },
                { name: "设置与音源", icon: "⚙️", index: 4 }
            ]

            delegate: Rectangle {
                id: navItem
                width: parent.width
                height: 44
                radius: 8

                property bool isSelected: root.currentIndex === modelData.index
                property bool isHovered: itemMouse.containsMouse

                color: isSelected ? Theme.bgCard : (isHovered ? Theme.bgCardHover : "transparent")
                border.color: isSelected ? Theme.accent : "transparent"
                border.width: isSelected ? 1 : 0

                // Left active indicator
                Rectangle {
                    visible: navItem.isSelected
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    width: 3
                    radius: 1.5
                    color: Theme.accent
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        text: modelData.icon
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: modelData.name
                        color: navItem.isSelected ? Theme.textPrimary : (navItem.isHovered ? Theme.textPrimary : Theme.textSecondary)
                        font.pixelSize: 13
                        font.weight: navItem.isSelected ? Font.Bold : Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Badges for Downloads & Playlist
                Rectangle {
                    visible: (modelData.index === 2 && backend.activeDownloadsCount > 0) ||
                             (modelData.index === 3 && backend.playlist.length > 0)
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: Math.max(18, badgeTxt.implicitWidth + 8)
                    radius: 9
                    color: modelData.index === 2 ? "#10B981" : Theme.accent

                    Text {
                        id: badgeTxt
                        anchors.centerIn: parent
                        color: "#FFFFFF"
                        font.pixelSize: 10
                        font.bold: true
                        text: {
                            if (modelData.index === 2) {
                                return backend.activeDownloadsCount + "/5"
                            } else if (modelData.index === 3) {
                                return backend.playlist.length
                            }
                            return ""
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = modelData.index
                        root.tabSelected(modelData.index)
                    }
                }
            }
        }
    }

    // Bottom Theme Switcher Pill (简洁主题切换)
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 40
        radius: 20
        color: Theme.bgCard
        border.color: Theme.border
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "🎨"
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "主题: " + Theme.themeNames[Theme.themeMode]
                color: Theme.textSecondary
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                Theme.nextTheme()
                backend.themeMode = Theme.themeMode
            }
        }
    }
}
