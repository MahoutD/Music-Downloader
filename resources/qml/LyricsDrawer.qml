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

    property string songTitle: ""
    property string songArtist: ""
    property string lyricsText: ""

    Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // Top Header
    Rectangle {
        id: header
        height: 60
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        color: Theme.bgHeader
        radius: 12

        // Flatten bottom corners
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 12
            color: Theme.bgHeader
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                text: "📝"
                font.pixelSize: 18
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: root.songTitle.length > 0 ? root.songTitle : "歌词信息"
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.textPrimary
                }
                Text {
                    text: root.songArtist.length > 0 ? root.songArtist : "无歌手信息"
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }
            }
        }

        // Close button
        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: closeMouse.containsMouse ? Theme.border : "transparent"
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: Theme.textSecondary
                font.pixelSize: 14
                font.bold: true
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }
        }
    }

    // Lyrics Content Area
    ScrollView {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        clip: true

        Text {
            width: root.width - 48
            text: root.lyricsText.length > 0 ? root.lyricsText : "暂无歌词内容..."
            color: Theme.textPrimary
            font.pixelSize: 14
            lineHeight: 1.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    function open(title, artist, lyrics) {
        root.songTitle = title
        root.songArtist = artist
        root.lyricsText = lyrics
        root.opacity = 1
    }

    function close() {
        root.opacity = 0
    }
}
